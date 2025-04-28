<?php
include 'config.php'; // koneksi database

header("Content-Type: application/json");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Origin: *");

// Ambil ID dari parameter (misalnya dari Flutter)
if (isset($_GET['id'])) {
    $id = $_GET['id'];

    $query = "SELECT nama, email, no_hp FROM users WHERE id = '$id'";
    $result = mysqli_query($conn, $query);

    if ($result) {
        if (mysqli_num_rows($result) > 0) {
            $data = mysqli_fetch_assoc($result);
            echo json_encode([
                "success" => true,
                "data" => $data
            ]);
        } else {
            echo json_encode([
                "success" => false,
                "message" => "Data tidak ditemukan"
            ]);
        }
    } else {
        echo json_encode([
            "success" => false,
            "message" => "Query gagal"
        ]);
    }
} else {
    echo json_encode([
        "success" => false,
        "message" => "ID tidak dikirim"
    ]);
}
?>
