<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php'; // koneksi ke DB

// Validasi parameter id
if (!isset($_GET['id'])) {
    http_response_code(400);
    echo json_encode(["message" => "Parameter ID tidak ditemukan."]);
    exit;
}

$productId = intval($_GET['id']);

try {
    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Ambil detail produk & rata-rata rating
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

    // Cek apakah produk ditemukan
    if (!$product) {
        http_response_code(404);
        echo json_encode(["message" => "Produk tidak ditemukan."]);
        exit;
    }

    // Konversi rating menjadi float bulat ke 1 desimal
    $product['rating'] = round(floatval($product['rating']), 1);

    // Ambil semua gambar
    $stmtImg = $conn->prepare("SELECT id, is_main, TO_BASE64(image_product) AS image_base64 FROM product_images WHERE product_id = ? ORDER BY is_main DESC");
    $stmtImg->execute([$productId]);
    $images = $stmtImg->fetchAll(PDO::FETCH_ASSOC);

    // Tambahkan gambar ke response
    $product['images'] = $images;

    echo json_encode($product);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>
