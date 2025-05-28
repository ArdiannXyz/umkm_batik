<?php
// Hapus semua whitespace dan output sebelumnya
ob_clean();
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, DELETE, OPTIONS');
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
$debug['step'] = 'Starting delete cart process';

try {
    // Create connection
    $conn = new mysqli($host, $user, $password, $database);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    $debug['step'] = 'Connected to database';
    
    // Get request method
    $method = $_SERVER['REQUEST_METHOD'];
    $debug['method'] = $method;
    
    // Handle different request methods
    if ($method === 'POST' || $method === 'DELETE') {
        // Get JSON input
        $input = json_decode(file_get_contents('php://input'), true);
        
        // Get parameters from JSON or GET
        $cart_id = isset($input['cart_id']) ? intval($input['cart_id']) : 
                  (isset($_GET['cart_id']) ? intval($_GET['cart_id']) : 0);
        $user_id = isset($input['user_id']) ? intval($input['user_id']) : 
                  (isset($_GET['user_id']) ? intval($_GET['user_id']) : 0);
        
        $debug['cart_id'] = $cart_id;
        $debug['user_id'] = $user_id;
        
        // Validate required parameters
        if ($cart_id <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'Cart ID is required and must be valid',
                'debug' => $debug
            ]);
            exit;
        }
        
        if ($user_id <= 0) {
            http_response_code(400);
            echo json_encode([
                'success' => false,
                'message' => 'User ID is required and must be valid',
                'debug' => $debug
            ]);
            exit;
        }
        
        $debug['step'] = 'Parameters validated';
        
        // First, verify that the cart item belongs to the user
        $verify_query = "SELECT id, product_id, quantity FROM cart WHERE id = ? AND user_id = ?";
        $verify_stmt = $conn->prepare($verify_query);
        
        if (!$verify_stmt) {
            throw new Exception("Prepare verify failed: " . $conn->error);
        }
        
        $verify_stmt->bind_param("ii", $cart_id, $user_id);
        $verify_stmt->execute();
        $verify_result = $verify_stmt->get_result();
        
        if ($verify_result->num_rows === 0) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'message' => 'Cart item not found or does not belong to user',
                'debug' => $debug
            ]);
            exit;
        }
        
        $cart_item = $verify_result->fetch_assoc();
        $debug['step'] = 'Cart item verified';
        $debug['cart_item'] = $cart_item;
        
        // Delete the cart item
        $delete_query = "DELETE FROM cart WHERE id = ? AND user_id = ?";
        $delete_stmt = $conn->prepare($delete_query);
        
        if (!$delete_stmt) {
            throw new Exception("Prepare delete failed: " . $conn->error);
        }
        
        $delete_stmt->bind_param("ii", $cart_id, $user_id);
        $delete_success = $delete_stmt->execute();
        
        if (!$delete_success) {
            throw new Exception("Delete failed: " . $delete_stmt->error);
        }
        
        $affected_rows = $delete_stmt->affected_rows;
        $debug['affected_rows'] = $affected_rows;
        
        if ($affected_rows > 0) {
            $debug['step'] = 'Cart item deleted successfully';
            
            // Get updated cart count for user
            $count_query = "SELECT COUNT(*) as total FROM cart WHERE user_id = ?";
            $count_stmt = $conn->prepare($count_query);
            $count_stmt->bind_param("i", $user_id);
            $count_stmt->execute();
            $count_result = $count_stmt->get_result();
            $count_data = $count_result->fetch_assoc();
            
            $response = [
                'success' => true,
                'message' => 'Cart item deleted successfully',
                'data' => [
                    'deleted_cart_id' => $cart_id,
                    'deleted_product_id' => $cart_item['product_id'],
                    'deleted_quantity' => $cart_item['quantity'],
                    'remaining_cart_items' => $count_data['total']
                ],
                'debug' => $debug
            ];
        } else {
            $response = [
                'success' => false,
                'message' => 'No cart item was deleted',
                'debug' => $debug
            ];
        }
        
        $conn->close();
        
    } else {
        http_response_code(405);
        echo json_encode([
            'success' => false,
            'message' => 'Method not allowed. Use POST or DELETE',
            'debug' => $debug
        ]);
        exit;
    }
    
    // Clean output buffer and send JSON
    ob_clean();
    echo json_encode($response, JSON_PRETTY_PRINT);
    
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