<?php
header('Content-Type: application/json');
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type");
include 'config.php'; // file koneksi ke database kamu

$id = $_POST['id'];
$nama = $_POST['nama'];
$email = $_POST['email'];
$no_hp = $_POST['no_hp'];

if (!$id || !$nama || !$email || !$no_hp) {
    echo json_encode(["success" => false, "message" => "Data tidak lengkap"]);
    exit;
}

$query = "UPDATE users SET nama='$nama', email='$email', no_hp='$no_hp' WHERE id=$id";

if (mysqli_query($conn, $query)) {
    echo json_encode(["success" => true, "message" => "Profil berhasil diperbarui"]);
} else {
    echo json_encode(["success" => false, "message" => "Gagal memperbarui profil"]);
}
?>
