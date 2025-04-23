<?php
include 'config.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

$response = array();

// Ambil data JSON dari Flutter
$data = json_decode(file_get_contents("php://input"), true);

// Validasi apakah semua data sudah diisi
if (!empty($data['nama']) && !empty($data['email']) && !empty($data['no_hp']) && !empty($data['password'])) {
    $nama = $data['nama'];
    $email = $data['email'];
    $no_hp = $data['no_hp'];
    $password = password_hash($data['password'], PASSWORD_BCRYPT);
    $role = $data['role'];
    // Cek apakah email sudah terdaftar
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $response['error'] = true;
        $response['message'] = "Email sudah terdaftar!";
    } else {
        // Gunakan prepared statement untuk keamanan
        $stmt = $conn->prepare("INSERT INTO users (nama, email, no_hp, password, role) VALUES (?, ?, ?, ?, ?)");
        $stmt->bind_param("sssss", $nama, $email, $no_hp, $password, $role);

        if ($stmt->execute()) {
            $response['error'] = false;
            $response['message'] = "Registrasi berhasil!";
        } else {
            $response['error'] = true;
            $response['message'] = "Gagal mendaftar!";
        }
    }
} else {
    $response['error'] = true;
    $response['message'] = "Semua kolom harus diisi!";
}

// Kembalikan response dalam format JSON
echo json_encode($response);
?>
