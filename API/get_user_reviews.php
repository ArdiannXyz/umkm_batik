<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");

require_once 'config.php';

if (!isset($_GET['user_id'])) {
    http_response_code(400);
    echo json_encode(["message" => "Parameter user_id tidak ditemukan."]);
    exit;
}

$user_id = intval($_GET['user_id']);

try {
    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $stmt = $conn->prepare("
        SELECT reviews.id, reviews.rating, reviews.komentar, reviews.created_at, 
               products.nama AS product_nama, products.id AS product_id
        FROM reviews
        JOIN products ON reviews.product_id = products.id
        WHERE reviews.user_id = ?
        ORDER BY reviews.created_at DESC
    ");
    $stmt->execute([$user_id]);
    $reviews = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode($reviews);
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>