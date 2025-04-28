<?php
include 'config.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$response = array();
$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['email']) && !empty($data['otp'])) {
    $email = $data['email'];
    $otp = $data['otp'];

    // Cek OTP
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = ? AND otp = ? AND otp_expiry > NOW()");
    $stmt->bind_param("si", $email, $otp);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // OTP valid
        $response['error'] = false;
        $response['message'] = "OTP valid.";
    } else {
        // OTP tidak valid atau expired
        $response['error'] = true;
        $response['message'] = "OTP salah atau sudah kadaluarsa.";
    }

    $stmt->close();
} else {
    $response['error'] = true;
    $response['message'] = "Email dan OTP wajib diisi.";
}

echo json_encode($response);

$conn->close();
?>
