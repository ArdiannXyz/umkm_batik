<?php
// Database connection configuration
require_once 'config.php';

// Set headers to handle JSON requests and responses
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Allow both GET and POST for debugging
if ($_SERVER["REQUEST_METHOD"] !== "POST" && $_SERVER["REQUEST_METHOD"] !== "GET") {
    sendResponse(false, "Only POST or GET methods are allowed");
    exit();
}

// Function for debugging
function debug_log($message, $data = null) {
    $log = date('Y-m-d H:i:s') . " - " . $message;
    if ($data !== null) {
        $log .= " - Data: " . print_r($data, true);
    }
    error_log($log);
}

// Get request data
$data = [];
if ($_SERVER["REQUEST_METHOD"] === "POST") {
    $rawData = file_get_contents("php://input");
    debug_log("Raw POST data", $rawData);
    $data = json_decode($rawData, true) ?: [];
}

debug_log("Request method", $_SERVER["REQUEST_METHOD"]);
debug_log("GET data", $_GET);
debug_log("POST data", $data);

// Determine order_id from various possible sources
$orderId = null;
if (isset($_GET['order_id'])) {
    $orderId = $_GET['order_id'];
    debug_log("Order ID from GET", $orderId);
} elseif (isset($data['order_id'])) {
    $orderId = $data['order_id'];
    debug_log("Order ID from POST body", $orderId);
} else {
    debug_log("No order_id found in request");
    sendResponse(false, "Missing required order_id");
    exit();
}

// Log the order ID type
debug_log("Order ID type before processing", gettype($orderId));
debug_log("Order ID value before processing", $orderId);

// Allow both numeric and string IDs
// No validation - accept whatever format is provided
$originalOrderId = $orderId; // Keep original for logging

// Try to handle both string and integer IDs
if (is_numeric($orderId)) {
    // If it's numeric, we can safely convert to int
    $orderId = (int)$orderId;
}

debug_log("Final order ID to use in queries", $orderId);
debug_log("Final order ID type", gettype($orderId));

$reason = isset($data['reason']) ? $data['reason'] : 'Payment timeout';

// DEBUGGING: Test database connection and query capability
try {
    // Test if we can access the orders table at all
    $testQuery = "SELECT COUNT(*) as count FROM orders";
    $testResult = $conn->query($testQuery);
    
    if ($testResult === false) {
        debug_log("Error accessing orders table", $conn->error);
        sendResponse(false, "Database error: " . $conn->error);
        exit();
    }
    
    $testData = $testResult->fetch_assoc();
    debug_log("Total orders in database", $testData['count']);
    
    // Test specifically for the requested order
    $testOrderQuery = "SELECT id, status FROM orders WHERE id = ?";
    $testOrderStmt = $conn->prepare($testOrderQuery);
    
    if ($testOrderStmt === false) {
        debug_log("Error preparing order query", $conn->error);
        sendResponse(false, "Database prepare error: " . $conn->error);
        exit();
    }
    
    // Bind parameter as string to handle both numeric and string IDs
    $testOrderStmt->bind_param("s", $orderId);
    $testOrderStmt->execute();
    $testOrderResult = $testOrderStmt->get_result();
    
    debug_log("Order query result rows", $testOrderResult->num_rows);
    
    if ($testOrderResult->num_rows === 0) {
        // If no order found, check if the database/table names are correct
        $checkTablesQuery = "SHOW TABLES";
        $tablesResult = $conn->query($checkTablesQuery);
        
        if ($tablesResult) {
            $tables = [];
            while ($table = $tablesResult->fetch_array(MYSQLI_NUM)) {
                $tables[] = $table[0];
            }
            debug_log("Available tables", $tables);
        }
        
        sendResponse(false, "Order ID $orderId not found in database");
        exit();
    }
    
    $orderData = $testOrderResult->fetch_assoc();
    debug_log("Found order data", $orderData);
    
    // After this point, we know the order exists
    
    // Check if status is valid for cancellation
    if ($orderData['status'] !== 'pending') {
        debug_log("Cannot cancel order with status", $orderData['status']);
        sendResponse(false, "Cannot cancel order. Current status: " . $orderData['status']);
        exit();
    }
    
} catch (Exception $e) {
    debug_log("Exception in database test", $e->getMessage());
    sendResponse(false, "Database test failed: " . $e->getMessage());
    exit();
}

// Start a transaction to ensure data integrity
$conn->begin_transaction();

try {
    // Update order status to cancelled
    $updateOrderQuery = "UPDATE orders SET status = 'cancelled' WHERE id = ?";
    $updateOrderStmt = $conn->prepare($updateOrderQuery);
    $updateOrderStmt->bind_param("s", $orderId);
    
    debug_log("Executing order update query", $updateOrderQuery);
    
    if (!$updateOrderStmt->execute()) {
        throw new Exception("Failed to update order status: " . $updateOrderStmt->error);
    }
    
    debug_log("Order status updated successfully. Affected rows", $updateOrderStmt->affected_rows);
    
    // Update payment status to failed
    $updatePaymentQuery = "UPDATE payments SET status_pembayaran = 'failed' WHERE order_id = ?";
    $updatePaymentStmt = $conn->prepare($updatePaymentQuery);
    $updatePaymentStmt->bind_param("s", $orderId);
    
    debug_log("Executing payment update query", $updatePaymentQuery);
    
    if (!$updatePaymentStmt->execute()) {
        throw new Exception("Failed to update payment status: " . $updatePaymentStmt->error);
    }
    
    debug_log("Payment status updated successfully. Affected rows", $updatePaymentStmt->affected_rows);
    
    // Get order items to restore stock
    $orderItemsQuery = "SELECT product_id, kuantitas FROM order_items WHERE order_id = ?";
    $orderItemsStmt = $conn->prepare($orderItemsQuery);
    $orderItemsStmt->bind_param("s", $orderId);
    
    debug_log("Executing order items query", $orderItemsQuery);
    
    $orderItemsStmt->execute();
    $orderItemsResult = $orderItemsStmt->get_result();
    
    debug_log("Order items found", $orderItemsResult->num_rows);
    
    // Restore stock for each item
    while ($item = $orderItemsResult->fetch_assoc()) {
        debug_log("Processing order item", $item);
        
        // Get stock ID from product
        $getStockIdQuery = "SELECT stok_id FROM products WHERE id = ?";
        $getStockIdStmt = $conn->prepare($getStockIdQuery);
        $getStockIdStmt->bind_param("i", $item['product_id']);
        
        debug_log("Executing stock ID query for product", $item['product_id']);
        
        $getStockIdStmt->execute();
        $stockIdResult = $getStockIdStmt->get_result();
        
        if ($stockIdResult->num_rows === 0) {
            debug_log("No stock found for product", $item['product_id']);
            throw new Exception("Stock not found for product ID: " . $item['product_id']);
        }
        
        $stockData = $stockIdResult->fetch_assoc();
        $stockId = $stockData['stok_id'];
        
        debug_log("Found stock ID", $stockId);
        
        // Update stock quantity
        $updateStockQuery = "UPDATE stocks SET quantity = quantity + ? WHERE id = ?";
        $updateStockStmt = $conn->prepare($updateStockQuery);
        $updateStockStmt->bind_param("ii", $item['kuantitas'], $stockId);
        
        debug_log("Executing stock update query", ['quantity' => $item['kuantitas'], 'stock_id' => $stockId]);
        
        if (!$updateStockStmt->execute()) {
            throw new Exception("Failed to restore stock: " . $updateStockStmt->error);
        }
        
        debug_log("Stock updated successfully. Affected rows", $updateStockStmt->affected_rows);
        
        // Check updated stock quantity
        $checkStockQuery = "SELECT quantity FROM stocks WHERE id = ?";
        $checkStockStmt = $conn->prepare($checkStockQuery);
        $checkStockStmt->bind_param("i", $stockId);
        $checkStockStmt->execute();
        $checkStockResult = $checkStockStmt->get_result();
        $updatedStockData = $checkStockResult->fetch_assoc();
        
        debug_log("Updated stock quantity", $updatedStockData['quantity']);
        
        if ($updatedStockData['quantity'] > 0) {
            // Update product status to available if it was out_of_stock
            $updateProductStatusQuery = "UPDATE products SET status = 'available' WHERE id = ? AND status = 'out_of_stock'";
            $updateProductStatusStmt = $conn->prepare($updateProductStatusQuery);
            $updateProductStatusStmt->bind_param("i", $item['product_id']);
            
            debug_log("Executing product status update for product", $item['product_id']);
            
            $updateProductStatusStmt->execute();
            
            debug_log("Product status update completed. Affected rows", $updateProductStatusStmt->affected_rows);
        }
    }
    
    // Commit the transaction
    $conn->commit();
    debug_log("Transaction committed successfully");
    
    // Success response
    sendResponse(true, "Order has been cancelled successfully", [
        'order_id' => $orderId,
        'reason' => $reason
    ]);
    
} catch (Exception $e) {
    // Rollback on error
    $conn->rollback();
    debug_log("Error occurred, transaction rolled back", $e->getMessage());
    sendResponse(false, "Error: " . $e->getMessage());
}

// Close connection
$conn->close();
debug_log("Database connection closed");

/**
 * Send JSON response back to client
 */
function sendResponse($success, $message, $data = []) {
    $response = [
        'success' => $success,
        'message' => $message
    ];
    
    if (!empty($data)) {
        $response['data'] = $data;
    }
    
    debug_log("Sending response", $response);
    echo json_encode($response);
}
?>