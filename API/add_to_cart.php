<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Database configuration
$host = 'localhost';
$username = 'root';
$password = '';
$database = 'umkm_batik';

try {
    // Create database connection
    $pdo = new PDO("mysql:host=$host;dbname=$database;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get JSON input
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    if (!isset($input['user_id']) || !isset($input['product_id']) || !isset($input['quantity'])) {
        echo json_encode([
            'success' => false, 
            'message' => 'Missing required fields: user_id, product_id, quantity'
        ]);
        exit;
    }
    
    $user_id = (int)$input['user_id'];
    $product_id = (int)$input['product_id'];
    $quantity = (int)$input['quantity'];
    
    // Validate input values
    if ($user_id <= 0 || $product_id <= 0 || $quantity <= 0) {
        echo json_encode([
            'success' => false, 
            'message' => 'Invalid input values'
        ]);
        exit;
    }
    
    // Check if user exists
    $stmt = $pdo->prepare("SELECT id FROM users WHERE id = ?");
    $stmt->execute([$user_id]);
    if (!$stmt->fetch()) {
        echo json_encode([
            'success' => false, 
            'message' => 'User not found'
        ]);
        exit;
    }
    
    // Check if product exists and get stock information
    $stmt = $pdo->prepare("
        SELECT p.id, p.nama, p.harga, s.quantity as stock 
        FROM products p 
        LEFT JOIN stocks s ON p.stok_id = s.id 
        WHERE p.id = ? AND p.status = 'available'
    ");
    $stmt->execute([$product_id]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$product) {
        echo json_encode([
            'success' => false, 
            'message' => 'Product not found or not available'
        ]);
        exit;
    }
    
    // Check stock availability
    $available_stock = (int)$product['stock'];
    if ($available_stock <= 0) {
        echo json_encode([
            'success' => false, 
            'message' => 'Product is out of stock'
        ]);
        exit;
    }
    
    // Check if requested quantity is available
    if ($quantity > $available_stock) {
        echo json_encode([
            'success' => false, 
            'message' => "Only $available_stock items available in stock"
        ]);
        exit;
    }
    
    // Start transaction
    $pdo->beginTransaction();
    
    try {
        // Check if item already exists in cart
        $stmt = $pdo->prepare("
            SELECT id, quantity as current_quantity 
            FROM cart 
            WHERE user_id = ? AND product_id = ?
        ");
        $stmt->execute([$user_id, $product_id]);
        $existing_item = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($existing_item) {
            // Update existing cart item
            $new_quantity = $existing_item['current_quantity'] + $quantity;
            
            // Check if total quantity exceeds stock
            if ($new_quantity > $available_stock) {
                echo json_encode([
                    'success' => false, 
                    'message' => "Cannot add $quantity items. Only " . ($available_stock - $existing_item['current_quantity']) . " more items can be added"
                ]);
                $pdo->rollBack();
                exit;
            }
            
            $stmt = $pdo->prepare("
                UPDATE cart 
                SET quantity = ?, updated_at = NOW() 
                WHERE id = ?
            ");
            $stmt->execute([$new_quantity, $existing_item['id']]);
            
            $message = "Cart updated successfully. Total quantity: $new_quantity";
            
        } else {
            // Add new item to cart
            $stmt = $pdo->prepare("
                INSERT INTO cart (user_id, product_id, quantity, added_at) 
                VALUES (?, ?, ?, NOW())
            ");
            $stmt->execute([$user_id, $product_id, $quantity]);
            
            $message = "Product added to cart successfully";
        }
        
        // Get updated cart count and total
        $stmt = $pdo->prepare("
            SELECT 
                COUNT(*) as cart_count,
                COALESCE(SUM(c.quantity), 0) as total_items,
                COALESCE(SUM(c.quantity * p.harga), 0) as total_price
            FROM cart c
            JOIN products p ON c.product_id = p.id
            WHERE c.user_id = ?
        ");
        $stmt->execute([$user_id]);
        $cart_info = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Commit transaction
        $pdo->commit();
        
        echo json_encode([
            'success' => true,
            'message' => $message,
            'cart_count' => (int)$cart_info['cart_count'],
            'total_items' => (int)$cart_info['total_items'],
            'total_price' => (float)$cart_info['total_price'],
            'product_name' => $product['nama']
        ]);
        
    } catch (Exception $e) {
        $pdo->rollBack();
        throw $e;
    }
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Database error: ' . $e->getMessage()
    ]);
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false, 
        'message' => 'Server error: ' . $e->getMessage()
    ]);
}
?>