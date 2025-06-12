<?php
include 'config.php';

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

$data = json_decode(file_get_contents('php://input'), true);
$question = isset($data['question']) ? strtolower(trim($data['question'])) : '';

if (empty($question)) {
    echo json_encode(['type' => 'error', 'message' => 'Pertanyaan tidak ditemukan.']);
    exit;
}

// Fungsi utilitas
function contains_keywords($text, $keywords) {
    foreach ($keywords as $keyword) {
        if (strpos($text, $keyword) !== false) return true;
    }
    return false;
}

$response = [];

switch (true) {
    case contains_keywords($question, ['stok', 'stock', 'tersedia', 'ketersediaan']):
        $response = [
            'type' => 'stock_steps',
            'message' => "Berikut cara mengecek stok barang:",
            'steps' => [
                "1. Buka halaman beranda aplikasi",
                "2. Pilih menu 'Produk' atau ketuk ikon pencarian",
                "3. Ketik nama produk yang ingin Anda cek",
                "4. Hasil pencarian akan menampilkan produk beserta status ketersediaannya",
                "5. Anda juga bisa melihat jumlah stok pada halaman detail produk"
            ]
        ];
        break;

    case contains_keywords($question, ['bayar', 'pembayaran']):
        $response = [
            'type' => 'payment_steps',
            'message' => "Berikut cara melakukan pembayaran:",
            'steps' => [
                "1. Pilih barang yang akan dibeli",
                "2. Lakukan pemesanan",
                "3. Pilih metode pembayaran",
                "4. Selesaikan pembayaran sesuai instruksi",
                "5. Status pesanan akan diperbarui setelah pembayaran berhasil"
            ]
        ];
        break;

    case contains_keywords($question, ['resi', 'cek resi', 'tracking', 'lacak']):
        $response = [
            'type' => 'tracking_steps',
            'message' => "Berikut cara melakukan cek resi:",
            'steps' => [
                "1. Salin resi pada menu 'detail pesanan'",
                "2. Buka browser, ketik 'cekresi.com'",
                "3. Masukkan nomor resi dan klik tombol",
                "4. Pilih ekspedisi untuk melihat info pengiriman"
            ]
        ];
        break;

    case contains_keywords($question, ['kontak', 'contact', 'hubungi']):
        $response = [
            'type' => 'contact_info',
            'message' => "Berikut informasi kontak kami:",
            'contacts' => [
                [
                    'name' => 'UMKM Batik Nusantara',
                    'phone' => '082112345678',
                    'email' => 'info@umkmbatik.com',
                    'hours' => 'Senin-Jumat: 08.00-17.00'
                ],
                [
                    'name' => 'Layanan Pelanggan',
                    'phone' => '082187654321',
                    'email' => 'cs@umkmbatik.com',
                    'hours' => 'Setiap hari: 08.00-20.00'
                ]
            ]
        ];
        break;

    case contains_keywords($question, ['tentang', 'about', 'profil']):
        $response = [
            'type' => 'about',
            'message' => "Tentang UMKM Batik Nusantara",
            'content' => "UMKM Batik Nusantara didirikan pada tahun 2015... [cut for brevity]"
        ];
        break;

    case ($question === 'menu' || contains_keywords($question, ['bantuan', 'help'])):
        $response = [
            'type' => 'help_menu',
            'message' => "Berikut menu bantuan yang tersedia:",
            'menu' => [
                "stok - Cara cek stok produk",
                "bayar - Cara melakukan pembayaran",
                "resi - Cara cek resi pengiriman",
                "kontak - Informasi kontak penjual",
                "tentang - Tentang UMKM Batik"
            ]
        ];
        break;

    default:
        $response = [
            'type' => 'unknown',
            'message' => "Maaf, saya belum dapat memahami pertanyaan Anda. Silakan ketik 'menu' untuk melihat bantuan.",
        ];
}

echo json_encode($response);
?>
