<?php
include 'config.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

// Inisialisasi array response
$response = array();

// Ambil data JSON dari Flutter
$data = json_decode(file_get_contents("php://input"), true);

// Validasi apakah email ada
if (!empty($data['email'])) {
    $email = $data['email'];

    // Cek apakah email ada di database
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Email ditemukan
        $response['error'] = false;
        $response['message'] = "Email ditemukan.";
    } else {
        // Email tidak ditemukan
        $response['error'] = true;
        $response['message'] = "Email tidak tersedia.";
    }

    $stmt->close();
} else {
    // Email kosong
    $response['error'] = true;
    $response['message'] = "Email tidak boleh kosong.";
}

// Kembalikan response dalam format JSON
echo json_encode($response);

$conn->close();
?>
