<?php
$host = "localhost";
$user = "root";  // Sesuaikan jika berbeda
$password = "";  // Sesuaikan jika berbeda
$database = "umkm_batik";

$conn = new mysqli($host, $user, $password, $database);

if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}
?>