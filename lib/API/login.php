<?php
include 'config.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$response = array();

// Ambil data JSON dari Flutter
$data = json_decode(file_get_contents("php://input"), true);

if (isset($data['email']) && isset($data['password'])) {
    $email = $data['email'];
    $password = $data['password'];

    // Cek apakah email ada di database
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $user = $result->fetch_assoc();

        // Verifikasi password yang dienkripsi
        if (password_verify($password, $user['password'])) {
            $response['error'] = false;
            $response['message'] = "Login berhasil!";
            $response['role'] = $user['role'];
            $response['user'] = [
                "id" => $user['id'],
                "nama" => $user['nama'],
                "email" => $user['email'],
                "no_hp" => $user['no_hp'],
                "role" => $user['role']
                
            ];
        } else {
            $response['error'] = true;
            $response['message'] = "Password salah!";
        }
    } else {
        $response['error'] = true;
        $response['message'] = "Email tidak ditemukan!";
    }
} else {
    $response['error'] = true;
    $response['message'] = "Data tidak lengkap!";
}

// Kirim respons JSON
echo json_encode($response);
?>