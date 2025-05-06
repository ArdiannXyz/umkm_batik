<?php
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");

require_once 'config.php';

try {
    $rawInput = file_get_contents("php://input");
    $input = json_decode($rawInput, true);

    if (!is_array($input)) {
        echo json_encode([
            "message" => "Input JSON tidak valid.",
            "raw_input" => $rawInput,
            "json_error" => json_last_error_msg()
        ]);
        exit;
    }

    if (
        !isset($input['product_id']) ||
        !isset($input['user_id']) ||
        !isset($input['rating']) ||
        !isset($input['komentar'])
    ) {
        http_response_code(400);
        echo json_encode(["message" => "Parameter tidak lengkap."]);
        exit;
    }

    $product_id = intval($input['product_id']);
    $user_id = intval($input['user_id']);
    $rating = floatval($input['rating']);
    $komentar = trim($input['komentar']);

    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    $stmt = $conn->prepare("INSERT INTO reviews (product_id, user_id, rating, komentar) VALUES (?, ?, ?, ?)");
    $stmt->execute([$product_id, $user_id, $rating, $komentar]);

    echo json_encode(["message" => "Review berhasil ditambahkan"]);

} catch (PDOException $e) {
    http_response_code(500);
    echo json_encode(["error" => $e->getMessage()]);
}
?>
