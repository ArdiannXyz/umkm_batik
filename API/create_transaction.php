<?php
// Database connection configuration
require_once 'config.php';

// Set headers to handle JSON requests and responses
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// Process only POST requests
if ($_SERVER["REQUEST_METHOD"] !== "POST") {
    sendResponse(false, "Only POST method is allowed");
    exit();
}

// Get JSON data from the request body
$data = json_decode(file_get_contents("php://input"), true);

// Validate required data
if (!validateRequiredFields($data)) {
    sendResponse(false, "Missing required data");
    exit();
}

// Start a transaction to ensure data integrity
$conn->begin_transaction();

try {
    // First, check if user_id exists in users table
    $userQuery = "SELECT id FROM umkm_batik.users WHERE id = ?";
    $userStmt = $conn->prepare($userQuery);
    $userStmt->bind_param("i", $data['user_id']);
    $userStmt->execute();
    $userResult = $userStmt->get_result();
    
    if ($userResult->num_rows === 0) {
        throw new Exception("Invalid user_id. User does not exist.");
    }
    
    // Generate unique order ID (Format: UMKM-YYYYMMDD-XXXX where XXXX is a sequential number)
    $orderID = generateOrderID($conn);
    
    // Insert into orders table
    $orderQuery = "INSERT INTO umkm_batik.orders 
                  (user_id, waktu_order, status, total_harga, alamat_pemesanan, metode_pengiriman, notes, created_at) 
                  VALUES (?, NOW(), 'pending', ?, ?, ?, ?, NOW())";
    
    $notes = isset($data['notes']) ? $data['notes'] : '';
    
    $orderStmt = $conn->prepare($orderQuery);
    $orderStmt->bind_param(
        "idsss",
        $data['user_id'],
        $data['total_harga'],
        $data['alamat_pemesanan'],
        $data['metode_pengiriman'],
        $notes
    );
    
    if (!$orderStmt->execute()) {
        throw new Exception("Failed to create order: " . $orderStmt->error);
    }
    
    $orderID_db = $conn->insert_id; // Get the auto-generated ID
    
    // Insert order items
    foreach ($data['items'] as $item) {
        // First check if product exists and has enough stock
        $productQuery = "SELECT p.id, p.stok_id, s.quantity 
                        FROM umkm_batik.products p 
                        JOIN umkm_batik.stocks s ON p.stok_id = s.id 
                        WHERE p.id = ? AND s.quantity >= ?";
        
        $productStmt = $conn->prepare($productQuery);
        $productStmt->bind_param("ii", $item['product_id'], $item['kuantitas']);
        $productStmt->execute();
        $productResult = $productStmt->get_result();
        
        if ($productResult->num_rows === 0) {
            throw new Exception("Product ID " . $item['product_id'] . " does not exist or has insufficient stock.");
        }
        
        $productData = $productResult->fetch_assoc();
        
        // Remove subtotal from the insert query since it's a generated column
        $itemQuery = "INSERT INTO umkm_batik.order_items 
                     (order_id, product_id, kuantitas, harga) 
                     VALUES (?, ?, ?, ?)";
        
        $itemStmt = $conn->prepare($itemQuery);
        
        $itemStmt->bind_param(
            "iiid",
            $orderID_db,
            $item['product_id'],
            $item['kuantitas'],
            $item['harga']
        );
        
        if (!$itemStmt->execute()) {
            throw new Exception("Failed to add order item: " . $itemStmt->error);
        }
        
        // Update product stock in the stocks table instead of products table
        updateProductStock($conn, $productData['stok_id'], $item['kuantitas']);
    }
    
    // Insert payment data
    $paymentQuery = "INSERT INTO umkm_batik.payments 
                    (order_id, metode_pembayaran, status_pembayaran, waktu_pembayaran) 
                    VALUES (?, ?, 'pending', NOW())";
    
    $paymentStmt = $conn->prepare($paymentQuery);
    $paymentStmt->bind_param(
        "is",
        $orderID_db,
        $data['metode_pembayaran']
    );
    
    if (!$paymentStmt->execute()) {
        throw new Exception("Failed to create payment record: " . $paymentStmt->error);
    }
    
    // Commit the transaction
    $conn->commit();
    
    // Success response
    sendResponse(true, "Transaction created successfully", [
        'order_id' => $orderID,
        'order_id_db' => $orderID_db,
        'total' => $data['total_harga'],
        'status' => 'pending',
        'payment_method' => $data['metode_pembayaran']
    ]);
    
} catch (Exception $e) {
    // Rollback on error
    $conn->rollback();
    sendResponse(false, "Error: " . $e->getMessage());
}

// Close connection
$conn->close();

/**
 * Generate a unique order ID
 * Format: UMKM-YYYYMMDD-XXXX (XXXX is a sequential number)
 */
function generateOrderID($conn) {
    $datePrefix = "" . date("");
    
    // Get the latest order ID for today
    $query = "SELECT MAX(id) as max_id FROM umkm_batik.orders 
              WHERE DATE(waktu_order) = CURDATE()";
    
    $result = $conn->query($query);
    $row = $result->fetch_assoc();
    
    // Generate sequence number (start from 0001)
    $sequenceNumber = 1;
    
    if ($row && $row['max_id']) {
        $sequenceNumber = $row['max_id'] + 1;
    }
    
    // Format the sequence number to 4 digits
    $formattedSequence = str_pad($sequenceNumber, 4, "0", STR_PAD_LEFT);
    
    return $datePrefix . "" . $formattedSequence;
}

/**
 * Update product stock after order
 * Modified to update the stocks table instead of products table
 */
function updateProductStock($conn, $stockId, $quantity) {
    // Update stock quantity in the stocks table
    $updateQuery = "UPDATE umkm_batik.stocks 
                   SET quantity = quantity - ? 
                   WHERE id = ?";
    
    $updateStmt = $conn->prepare($updateQuery);
    $updateStmt->bind_param("ii", $quantity, $stockId);
    
    if (!$updateStmt->execute()) {
        throw new Exception("Failed to update product stock: " . $updateStmt->error);
    }
    
    // Check if the product is out of stock after update
    $checkQuery = "SELECT s.quantity, p.id as product_id 
                  FROM umkm_batik.stocks s
                  JOIN umkm_batik.products p ON s.id = p.stok_id
                  WHERE s.id = ?";
                  
    $checkStmt = $conn->prepare($checkQuery);
    $checkStmt->bind_param("i", $stockId);
    $checkStmt->execute();
    $result = $checkStmt->get_result();
    
    while ($row = $result->fetch_assoc()) {
        if ($row['quantity'] <= 0) {
            // Update product status to out_of_stock
            $statusQuery = "UPDATE umkm_batik.products 
                          SET status = 'out_of_stock' 
                          WHERE id = ?";
            
            $statusStmt = $conn->prepare($statusQuery);
            $statusStmt->bind_param("i", $row['product_id']);
            $statusStmt->execute();
        }
    }
}

/**
 * Validate that all required fields are present
 */
function validateRequiredFields($data) {
    $requiredFields = ['user_id', 'total_harga', 'alamat_pemesanan', 'metode_pengiriman', 'metode_pembayaran', 'items'];
    
    foreach ($requiredFields as $field) {
        if (!isset($data[$field])) {
            return false;
        }
    }
    
    // Check if items array is not empty
    if (empty($data['items']) || !is_array($data['items'])) {
        return false;
    }
    
    // Validate each item
    foreach ($data['items'] as $item) {
        if (!isset($item['product_id']) || !isset($item['kuantitas']) || !isset($item['harga'])) {
            return false;
        }
    }
    
    return true;
}

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
    
    echo json_encode($response);
}
?>