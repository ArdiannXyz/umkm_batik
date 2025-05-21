<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: DELETE, POST, PUT, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, X-HTTP-Method-Override");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

// Get the real method from header or default to the actual method
$method = $_SERVER['REQUEST_METHOD'];
if (isset($_SERVER['HTTP_X_HTTP_METHOD_OVERRIDE'])) {
    $method = $_SERVER['HTTP_X_HTTP_METHOD_OVERRIDE'];
}

// Handle both DELETE or POST with override
if ($method !== 'DELETE' && !($method === 'POST' && isset($_SERVER['HTTP_X_HTTP_METHOD_OVERRIDE']))) {
    http_response_code(405);
    echo json_encode(["message" => "Method not allowed", "method" => $method]);
    exit;
}

// Get JSON data from request body
$input = file_get_contents('php://input');
$data = json_decode($input, true);

if ($data === null) {
    http_response_code(400);
    echo json_encode([
        "message" => "Invalid JSON data", 
        "raw_input" => $input
    ]);
    exit;
}

// Check if all required fields are present
if (!isset($data['user_id']) || !isset($data['product_id'])) {
    http_response_code(400);
    echo json_encode([
        "message" => "Fields diperlukan: user_id, product_id",
        "received" => $data
    ]);
    exit;
}

$user_id = intval($data['user_id']);
$product_id = intval($data['product_id']);

try {
    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Delete the review
    $stmt = $conn->prepare("
        DELETE FROM reviews 
        WHERE user_id = ? AND product_id = ?
    ");
    $stmt->execute([$user_id, $product_id]);
    
    if ($stmt->rowCount() === 0) {
        http_response_code(404);
        echo json_encode(["message" => "Review tidak ditemukan"]);
        exit;
    }
    
    echo json_encode(["message" => "Review berhasil dihapus", "success" => true]);
    
} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>