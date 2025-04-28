<?php
include 'config.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$response = array();
$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['email']) && !empty($data['password'])) {
    $email = $data['email'];
    $password = password_hash($data['password'], PASSWORD_DEFAULT); // Hash password baru

    // Update password di database
    $stmt = $conn->prepare("UPDATE users SET password = ?, otp = NULL, otp_expiry = NULL WHERE email = ?");
    $stmt->bind_param("ss", $password, $email);

    if ($stmt->execute()) {
        $response['error'] = false;
        $response['message'] = "Password berhasil diperbarui.";
    } else {
        $response['error'] = true;
        $response['message'] = "Gagal memperbarui password.";
    }

    $stmt->close();
} else {
    $response['error'] = true;
    $response['message'] = "Email dan Password wajib diisi.";
}

echo json_encode($response);

$conn->close();
?>
