<?php
// Hapus semua whitespace dan output sebelumnya
ob_clean();
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Database configuration
$host = "localhost";
$user = "root";
$password = "";
$database = "umkm_batik";

// Start debugging
$debug = [];
$debug['step'] = 'Starting';
$debug['method'] = $_SERVER['REQUEST_METHOD'];

try {
    // Create connection
    $conn = new mysqli($host, $user, $password, $database);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    $debug['step'] = 'Connected to database';
    
    if ($_SERVER['REQUEST_METHOD'] === 'PUT') {
        // Update cart item quantity
        $input = json_decode(file_get_contents('php://input'), true);
        $debug['input'] = $input;
        
        if (!isset($input['cart_id']) || !isset($input['quantity']) || !isset($input['user_id'])) {
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => 'Missing required fields: cart_id, quantity, user_id',
                'debug' => $debug
            ]);
            exit;
        }
        
        $cart_id = intval($input['cart_id']);
        $quantity = intval($input['quantity']);
        $user_id = intval($input['user_id']);
        
        $debug['cart_id'] = $cart_id;
        $debug['quantity'] = $quantity;
        $debug['user_id'] = $user_id;
        
        if ($quantity <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => 'Quantity must be greater than 0',
                'debug' => $debug
            ]);
            exit;
        }
        
        // Verify cart item belongs to user and get product info
        $verify_query = "SELECT 
                            c.id as cart_id,
                            c.product_id,
                            c.quantity as current_quantity,
                            c.user_id,
                            p.nama as product_name,
                            p.harga as product_price,
                            s.quantity as stock_quantity
                         FROM cart c
                         INNER JOIN products p ON c.product_id = p.id
                         LEFT JOIN stocks s ON p.stok_id = s.id
                         WHERE c.id = ? AND c.user_id = ?";
        
        $stmt = $conn->prepare($verify_query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param("ii", $cart_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $cart_item = $result->fetch_assoc();
        
        $debug['step'] = 'Cart item verified';
        
        if (!$cart_item) {
            http_response_code(404);
            echo json_encode([
                'success' => false, 
                'message' => 'Cart item not found or unauthorized access',
                'debug' => $debug
            ]);
            exit;
        }
        
        // Check stock availability
        $stock_quantity = intval($cart_item['stock_quantity']);
        if ($quantity > $stock_quantity) {
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => "Only {$stock_quantity} items available in stock",
                'available_stock' => $stock_quantity,
                'requested_quantity' => $quantity,
                'debug' => $debug
            ]);
            exit;
        }
        
        // Update cart item quantity
        $update_query = "UPDATE cart SET quantity = ?, updated_at = NOW() WHERE id = ? AND user_id = ?";
        $stmt = $conn->prepare($update_query);
        if (!$stmt) {
            throw new Exception("Prepare update failed: " . $conn->error);
        }
        
        $stmt->bind_param("iii", $quantity, $cart_id, $user_id);
        $update_result = $stmt->execute();
        
        if (!$update_result) {
            throw new Exception("Update failed: " . $stmt->error);
        }
        
        $debug['step'] = 'Cart updated successfully';
        
        // Calculate new subtotal
        $product_price = floatval($cart_item['product_price']);
        $new_subtotal = $product_price * $quantity;
        
        ob_clean();
        echo json_encode([
            'success' => true,
            'message' => 'Cart item updated successfully',
            'data' => [
                'cart_id' => $cart_id,
                'product_name' => $cart_item['product_name'],
                'old_quantity' => intval($cart_item['current_quantity']),
                'new_quantity' => $quantity,
                'product_price' => $product_price,
                'new_subtotal' => $new_subtotal
            ],
            'debug' => $debug
        ], JSON_PRETTY_PRINT);
        
    } elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
        // Remove cart item
        $input = json_decode(file_get_contents('php://input'), true);
        $debug['input'] = $input;
        
        if (!isset($input['cart_id']) || !isset($input['user_id'])) {
            http_response_code(400);
            echo json_encode([
                'success' => false, 
                'message' => 'Missing required fields: cart_id, user_id',
                'debug' => $debug
            ]);
            exit;
        }
        
        $cart_id = intval($input['cart_id']);
        $user_id = intval($input['user_id']);
        
        $debug['cart_id'] = $cart_id;
        $debug['user_id'] = $user_id;
        
        // Verify cart item belongs to user and get product info
        $verify_query = "SELECT 
                            c.id as cart_id,
                            c.product_id,
                            c.quantity,
                            c.user_id,
                            p.nama as product_name
                         FROM cart c
                         INNER JOIN products p ON c.product_id = p.id
                         WHERE c.id = ? AND c.user_id = ?";
        
        $stmt = $conn->prepare($verify_query);
        if (!$stmt) {
            throw new Exception("Prepare failed: " . $conn->error);
        }
        
        $stmt->bind_param("ii", $cart_id, $user_id);
        $stmt->execute();
        $result = $stmt->get_result();
        $cart_item = $result->fetch_assoc();
        
        $debug['step'] = 'Cart item verified for deletion';
        
        if (!$cart_item) {
            http_response_code(404);
            echo json_encode([
                'success' => false, 
                'message' => 'Cart item not found or unauthorized access',
                'debug' => $debug
            ]);
            exit;
        }
        
        // Delete cart item
        $delete_query = "DELETE FROM cart WHERE id = ? AND user_id = ?";
        $stmt = $conn->prepare($delete_query);
        if (!$stmt) {
            throw new Exception("Prepare delete failed: " . $conn->error);
        }
        
        $stmt->bind_param("ii", $cart_id, $user_id);
        $delete_result = $stmt->execute();
        
        if (!$delete_result) {
            throw new Exception("Delete failed: " . $stmt->error);
        }
        
        $debug['step'] = 'Cart item deleted successfully';
        
        ob_clean();
        echo json_encode([
            'success' => true,
            'message' => 'Item removed from cart successfully',
            'data' => [
                'cart_id' => $cart_id,
                'product_name' => $cart_item['product_name'],
                'removed_quantity' => intval($cart_item['quantity'])
            ],
            'debug' => $debug
        ], JSON_PRETTY_PRINT);
        
    } else {
        http_response_code(405);
        ob_clean();
        echo json_encode([
            'success' => false, 
            'message' => 'Method not allowed. Only PUT and DELETE are supported.',
            'debug' => $debug
        ]);
    }
    
    $conn->close();
    
} catch (Exception $e) {
    http_response_code(500);
    $debug['error'] = $e->getMessage();
    $debug['step'] = 'Error occurred';
    
    ob_clean();
    echo json_encode([
        'success' => false, 
        'message' => 'Server error occurred',
        'error' => $e->getMessage(),
        'debug' => $debug
    ], JSON_PRETTY_PRINT);
}

ob_end_flush();
?>