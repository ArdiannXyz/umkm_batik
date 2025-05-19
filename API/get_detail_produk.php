<?php

require_once 'config.php';

header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Check if ID parameter exists
if (!isset($_GET['id'])) {
    http_response_code(400);
    echo json_encode(["message" => "Parameter ID tidak ditemukan."]);
    exit;
}

$productId = intval($_GET['id']);

try {
    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Get product details
    $stmt = $conn->prepare("
        SELECT 
            p.id, 
            p.nama, 
            p.deskripsi, 
            p.harga, 
            p.stok_id,
            p.status,
            p.rating,
            p.created_at,
            s.quantity
        FROM products p
        LEFT JOIN stocks s ON p.stok_id = s.id
        WHERE p.id = ?
    ");
    $stmt->execute([$productId]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Check if product exists
    if (!$product) {
        http_response_code(404);
        echo json_encode(["message" => "Produk tidak ditemukan."]);
        exit;
    }
    
    // Convert rating to float
    $product['rating'] = floatval($product['rating']);
    
    // Get all images with proper encoding
    $stmtImg = $conn->prepare("
        SELECT 
            id, 
            product_id,
            is_main,
            CONCAT('data:image/jpeg;base64,', TO_BASE64(image_product)) AS image_base64 
        FROM product_images 
        WHERE product_id = ? 
        ORDER BY is_main DESC
    ");
    $stmtImg->execute([$productId]);
    $images = $stmtImg->fetchAll(PDO::FETCH_ASSOC);
    
    // Add images to response
    $product['images'] = $images;
    
    echo json_encode($product);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>