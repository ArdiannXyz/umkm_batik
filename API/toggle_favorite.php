<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$data = json_decode(file_get_contents("php://input"), true);
file_put_contents("log.txt", json_encode($data));
$user_id = $data['user_id'] ?? null;
$product_id = $data['product_id'] ?? null;

if (!$user_id || !$product_id) {
    echo json_encode(['success' => false, 'message' => 'Missing parameters']);
    exit();
}

// Check if the favorite already exists
$checkSql = "SELECT id FROM favorites WHERE user_id = ? AND product_id = ?";
$stmt = $conn->prepare($checkSql);
$stmt->bind_param("ii", $user_id, $product_id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    // Already favorited → Remove
    $deleteSql = "DELETE FROM favorites WHERE user_id = ? AND product_id = ?";
    $deleteStmt = $conn->prepare($deleteSql);
    $deleteStmt->bind_param("ii", $user_id, $product_id);
    $deleteStmt->execute();

    echo json_encode(['success' => true, 'favorited' => false]);
} else {
    // Not favorited → Add
    $insertSql = "INSERT INTO favorites (user_id, product_id) VALUES (?, ?)";
    $insertStmt = $conn->prepare($insertSql);
    $insertStmt->bind_param("ii", $user_id, $product_id);
    $insertStmt->execute();

    echo json_encode(['success' => true, 'favorited' => true]);
}

$conn->close();
?>
