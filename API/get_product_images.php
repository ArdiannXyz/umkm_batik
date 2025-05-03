<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
require_once 'config.php'; // koneksi ke DB

if (!isset($_GET['product_id'])) {
    echo json_encode(["error" => "product_id is required"]);
    exit;
}

$productId = intval($_GET['product_id']);

try {
    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $stmt = $conn->prepare("SELECT id, is_main, TO_BASE64(image_product) AS image_base64 FROM product_images WHERE product_id = ? ORDER BY is_main DESC");
    $stmt->execute([$productId]);
    $images = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($images);
} catch (PDOException $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>