<?php
include 'config.php';
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

// Load PHPMailer
require 'src/PHPMailer.php';
require 'src/SMTP.php';
require 'src/Exception.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$response = array();
$data = json_decode(file_get_contents("php://input"), true);

if (!empty($data['email'])) {
    $email = $data['email'];

    $stmt = $conn->prepare("SELECT id FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        // Email ditemukan

        // Generate OTP
        $otp = rand(100000, 999999);

        // Simpan OTP ke database
        $update = $conn->prepare("UPDATE users SET otp = ?, otp_expiry = DATE_ADD(NOW(), INTERVAL 5 MINUTE) WHERE email = ?");
        $update->bind_param("is", $otp, $email);
        $update->execute();

        // Kirim OTP via Email
        $mail = new PHPMailer(true);

        try {
            $mail->isSMTP();
            $mail->Host = 'smtp.gmail.com'; // Ganti
            $mail->SMTPAuth = true;
            $mail->Username = 'e41230685@student.polije.ac.id'; // Ganti
            $mail->Password = 'xqfk cqjk lfuy djeb'; // Ganti
            $mail->SMTPSecure = 'tls';
            $mail->Port = 587;

            $mail->setFrom('e41230685@student.polije.ac.id', 'UMKM Batik');
            $mail->addAddress($email);

            $mail->isHTML(true);
            $mail->Subject = 'Kode OTP Reset Password';
            $mail->Body    = "Kode OTP Anda untuk reset password adalah: <b>$otp</b><br> Berlaku selama 5 menit.";
            $mail->AltBody = "Kode OTP Anda adalah: $otp (berlaku 5 menit).";

            $mail->send();

            $response['error'] = false;
            $response['message'] = "Kode OTP telah dikirim ke email.";
        } catch (Exception $e) {
            $response['error'] = true;
            $response['message'] = "Gagal mengirim email: {$mail->ErrorInfo}";
        }

    } else {
        $response['error'] = true;
        $response['message'] = "Email tidak tersedia.";
    }

    $stmt->close();
} else {
    $response['error'] = true;
    $response['message'] = "Email tidak boleh kosong.";
}

echo json_encode($response);

$conn->close();
?>
