<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
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

try {
    // Create connection
    $conn = new mysqli($host, $user, $password, $database);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    $debug['step'] = 'Connected to database';
    
    // Get user_id from query parameter
    $user_id = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
    $debug['user_id'] = $user_id;
    
    if ($user_id <= 0) {
        http_response_code(400);
        echo json_encode([
            'success' => false,
            'message' => 'User ID is required and must be valid',
            'debug' => $debug
        ]);
        exit;
    }
    
    $debug['step'] = 'User ID validated';
    
    // First, let's check if cart table exists and has data
    $check_query = "SELECT COUNT(*) as total FROM cart WHERE user_id = ?";
    $stmt = $conn->prepare($check_query);
    
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $check_result = $stmt->get_result();
    $check_data = $check_result->fetch_assoc();
    
    $debug['cart_count'] = $check_data['total'];
    $debug['step'] = 'Cart count checked';
    
    // Query utama untuk mengambil data cart beserta detail produk dan stok
    $query = "SELECT 
                c.id as cart_id,
                c.product_id,
                c.quantity as cart_quantity,
                c.added_at,
                c.updated_at,
                p.nama as product_name,
                p.deskripsi as product_description,
                p.harga as product_price,
                p.stok_id,
                p.status as product_status,
                p.rating as product_rating,
                p.created_at as product_created_at,
                s.quantity as stock_quantity,
                s.updated_at as stock_updated_at
              FROM cart c 
              INNER JOIN products p ON c.product_id = p.id
              LEFT JOIN stocks s ON p.stok_id = s.id
              WHERE c.user_id = ?
              ORDER BY c.updated_at DESC";
    
    $stmt = $conn->prepare($query);
    
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param("i", $user_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $debug['step'] = 'Query executed';
    
    $cart_items = [];
    $total_amount = 0;
    
    while ($row = $result->fetch_assoc()) {
        // Ambil gambar produk secara terpisah
        $images = [];
        $image_query = "SELECT id, is_main FROM product_images WHERE product_id = ? ORDER BY is_main DESC, id ASC";
        $image_stmt = $conn->prepare($image_query);
        
        if ($image_stmt) {
            $image_stmt->bind_param("i", $row['product_id']);
            $image_stmt->execute();
            $image_result = $image_stmt->get_result();
            
            while ($img_row = $image_result->fetch_assoc()) {
                $images[] = [
                    'id' => intval($img_row['id']),
                    'image_url' => 'get_main_product_images.php?id=' . $img_row['id'], // URL untuk mengambil gambar
                    'is_main' => intval($img_row['is_main']) === 1
                ];
            }
            $image_stmt->close();
        }
        
        // Calculate subtotal for this item
        $cart_quantity = intval($row['cart_quantity']);
        $product_price = floatval($row['product_price']);
        $subtotal = $product_price * $cart_quantity;
        $total_amount += $subtotal;
        
        // Check stock availability
        $stock_quantity = intval($row['stock_quantity']);
        $is_available = $stock_quantity >= $cart_quantity;
        
        $cart_items[] = [
            'cart_id' => intval($row['cart_id']),
            'product_id' => intval($row['product_id']),
            'quantity' => $cart_quantity,
            'subtotal' => $subtotal,
            'added_at' => $row['added_at'],
            'updated_at' => $row['updated_at'],
            'is_available' => $is_available,
            'product' => [
                'id' => intval($row['product_id']),
                'nama' => $row['product_name'],
                'deskripsi' => $row['product_description'],
                'harga' => $product_price,
                'stok_id' => intval($row['stok_id']),
                'status' => $row['product_status'],
                'rating' => $row['product_rating'] ? floatval($row['product_rating']) : null,
                'created_at' => $row['product_created_at'],
                'stock' => [
                    'quantity' => $stock_quantity,
                    'updated_at' => $row['stock_updated_at'],
                    'is_sufficient' => $is_available
                ],
                'images' => $images
            ]
        ];
    }
    
    $debug['step'] = 'Data processed';
    $debug['items_found'] = count($cart_items);
    
    // Calculate summary with availability check
    $available_items = array_filter($cart_items, function($item) {
        return $item['is_available'];
    });
    
    $available_total = array_sum(array_map(function($item) {
        return $item['is_available'] ? $item['subtotal'] : 0;
    }, $cart_items));
    
    // Prepare response
    $response = [
        'success' => true,
        'message' => 'Cart items retrieved successfully',
        'data' => [
            'cart_items' => $cart_items,
            'summary' => [
                'total_items' => count($cart_items),
                'total_quantity' => array_sum(array_column($cart_items, 'quantity')),
                'total_amount' => $total_amount,
                'available_items' => count($available_items),
                'available_total_amount' => $available_total,
                'has_unavailable_items' => count($available_items) < count($cart_items)
            ]
        ],
        'debug' => $debug
    ];
    
    $conn->close();
    
    echo json_encode($response, JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    $debug['error'] = $e->getMessage();
    $debug['step'] = 'Error occurred';
    
    echo json_encode([
        'success' => false,
        'message' => 'Server error occurred',
        'error' => $e->getMessage(),
        'debug' => $debug
    ], JSON_PRETTY_PRINT);
}
?>