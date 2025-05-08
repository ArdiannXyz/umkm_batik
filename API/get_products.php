<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';

// Handle preflight CORS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Ambil semua produk + stok
$sql = "SELECT p.*, s.quantity 
        FROM products p 
        LEFT JOIN stocks s ON p.stok_id = s.id 
        WHERE p.status = 'available' 
        ORDER BY p.created_at DESC";

$result = $conn->query($sql);

$products = [];

if ($result && $result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        $products[] = $row;
    }

    // Ambil semua gambar produk (dalam base64)
    $imgResult = $conn->query("SELECT id, product_id, is_main, TO_BASE64(image_product) AS image_product FROM product_images ORDER BY is_main DESC");

    $images = [];
    if ($imgResult && $imgResult->num_rows > 0) {
        while ($img = $imgResult->fetch_assoc()) {
            $img['image_product'] = str_replace(["\r", "\n"], '', $img['image_product']);
            $images[] = $img;
        }
    }

    // Kelompokkan gambar berdasarkan product_id
    $imageMap = [];
    foreach ($images as $img) {
        $pid = $img['product_id'];
        if (!isset($imageMap[$pid])) {
            $imageMap[$pid] = [];
        }
        $imageMap[$pid][] = $img;
    }

    // Ambil semua rata-rata rating produk
    $ratingResult = $conn->query("SELECT product_id, ROUND(AVG(rating), 1) AS avg_rating FROM reviews GROUP BY product_id");

    $ratingMap = [];
    if ($ratingResult && $ratingResult->num_rows > 0) {
        while ($ratingRow = $ratingResult->fetch_assoc()) {
            $ratingMap[$ratingRow['product_id']] = floatval($ratingRow['avg_rating']);
        }
    }

    // Tambahkan gambar & rating ke setiap produk
    foreach ($products as &$product) {
        $pid = $product['id'];
        $product['images'] = $imageMap[$pid] ?? [];
        $product['rating'] = $ratingMap[$pid] ?? 0.0;
    }

    echo json_encode([
        'success' => true,
        'data' => $products
    ]);
} else {  
    echo json_encode([
        'success' => true,
        'data' => []
    ]);
}

$conn->close();
?>
