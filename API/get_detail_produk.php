<?php
// Headers
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");

// Database configuration
$host = "localhost"; // Your database host
$database = "umkm_batik"; // Your database name
$user = "root"; // Your database username
$password = ""; // Your database password (likely empty for local Laragon setup)

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
    
    // Get product details & average rating
    $stmt = $conn->prepare("
        SELECT 
            p.id, p.nama, p.deskripsi, p.harga, p.stok_id,
            COALESCE(AVG(r.rating), 0) AS rating
        FROM products p
        LEFT JOIN reviews r ON r.product_id = p.id
        WHERE p.id = ?
        GROUP BY p.id
    ");
    $stmt->execute([$productId]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Check if product exists
    if (!$product) {
        http_response_code(404);
        echo json_encode(["message" => "Produk tidak ditemukan."]);
        exit;
    }
    
    // Convert rating to float with 1 decimal place
    $product['rating'] = round(floatval($product['rating']), 1);
    
    // Get all images with proper base64 encoding
    $stmtImg = $conn->prepare("
        SELECT 
            id, 
            is_main, 
            CONCAT('data:image/jpeg;base64,', TO_BASE64(image_product)) AS image_base64 
        FROM product_images 
        WHERE product_id = ? 
        ORDER BY is_main DESC
    ");
    $stmtImg->execute([$productId]);
    $images = $stmtImg->fetchAll(PDO::FETCH_ASSOC);
    
    // Add images to response directly as an array (to match Flutter code expectations)
    $product['images'] = $images;
    
    echo json_encode($product);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>