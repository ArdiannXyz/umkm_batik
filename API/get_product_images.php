<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php'; // Koneksi database

// Pastikan hanya metode GET yang diizinkan
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405); // Method Not Allowed
    echo json_encode(["error" => "Only GET method is allowed"]);
    exit;
}

// Ambil product ID dari query string
if (isset($_GET['id'])) {
    $productId = intval($_GET['id']);
} elseif (isset($_GET['product_id'])) {
    $productId = intval($_GET['product_id']);
} else {
    echo json_encode(["error" => "product_id or id is required"]);
    exit;
}

// Validasi ID
if ($productId <= 0) {
    echo json_encode(["error" => "Invalid product_id"]);
    exit;
}

try {
    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $conn->prepare("SELECT id, is_main, TO_BASE64(image_product) AS image_base64 FROM product_images WHERE product_id = ? ORDER BY is_main DESC");
    $stmt->execute([$productId]);
    $images = $stmt->fetchAll(PDO::FETCH_ASSOC);

    if (empty($images)) {
        echo json_encode(["message" => "No images found for this product."]);
    } else {
        echo json_encode($images);
    }
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => "Database error: " . $e->getMessage()]);
}
?>
