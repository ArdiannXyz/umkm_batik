<?php
// chatbot_api.php
include 'config.php'; // File koneksi database Anda

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

// Menerima pertanyaan dari Flutter
$data = json_decode(file_get_contents('php://input'), true);
$question = strtolower($data['question']);

$response = [];

// Cek stok barang - Hanya berikan langkah-langkah
if (strpos($question, 'stok') !== false || strpos($question, 'stock') !== false || 
    strpos($question, 'tersedia') !== false || strpos($question, 'ketersediaan') !== false) {
    
    $response['type'] = 'stock_steps';
    $response['message'] = "Berikut cara mengecek stok barang:";
    $response['steps'] = [
        "1. Buka halaman beranda aplikasi",
        "2. Pilih menu 'Produk' atau ketuk ikon pencarian",
        "3. Ketik nama produk yang ingin Anda cek (contoh: 'batik mega mendung')",
        "4. Hasil pencarian akan menampilkan produk beserta status ketersediaannya",
        "5. Anda juga bisa melihat jumlah stok pada halaman detail produk"
    ];
}
// Cara pembayaran
else if (strpos($question, 'bayar') !== false || strpos($question, 'pembayaran') !== false) {
    $response['type'] = 'payment_steps';
    $response['message'] = "Berikut cara melakukan pembayaran:";
    $response['steps'] = [
        "1. Pilih barang yang akan dibeli",
        "2. Lakukan pemesanan",
        "3. Pilih metode pembayaran (Transfer Bank, E-wallet, atau QRIS)",
        "4. Selesaikan pembayaran sesuai instruksi",
        "5. Status pesanan akan diperbarui otomatis setelah pembayaran berhasil"
    ];
}
// Cara cek resi
else if (strpos($question, 'resi') !== false || strpos($question, 'cek resi') !== false || 
         strpos($question, 'tracking') !== false || strpos($question, 'lacak') !== false) {
    $response['type'] = 'tracking_steps';
    $response['message'] = "Berikut cara melakukan cek resi:";
    $response['steps'] = [
        "1. Salin resi yang ada pada menu 'detail pesanan'",
        "2. Buka aplikasi browser anda seperti Google Chrome",
        "3. Ketik 'cekresi.com' pada pencarian lalu tekan enter",
        "4. Tempel/paste no.resi kalian pada kolom dan klik tombol",
        "5. Pilih ekspedisi dan lihat pada detail paket untuk informasi pengirimannya"
    ];
}
// Produk berdasarkan kategori
else if (strpos($question, 'kategori') !== false || strpos($question, 'category') !== false) {
    $categoryName = extractCategoryName($question);
    
    if ($categoryName) {
        $query = "SELECT p.nama, p.harga, p.status
                  FROM umkm_batik_products p
                  JOIN categories c ON p.category_id = c.id
                  WHERE c.name LIKE '%$categoryName%' AND p.status = 'available'
                  LIMIT 5";
        $result = mysqli_query($conn, $query);
        
        if (mysqli_num_rows($result) > 0) {
            $response['type'] = 'category_products';
            $response['data'] = [];
            
            while ($row = mysqli_fetch_assoc($result)) {
                $response['data'][] = [
                    'nama_produk' => $row['nama'],
                    'harga' => "Rp " . number_format($row['harga'], 0, ',', '.'),
                    'status' => $row['status']
                ];
            }
            
            $response['message'] = "Berikut produk dalam kategori $categoryName:";
        } else {
            $response['message'] = "Maaf, tidak ditemukan produk dalam kategori '$categoryName'.";
        }
    } else {
        $response['message'] = "Silakan sebutkan kategori yang ingin Anda cari.";
    }
}
// Kontak informasi
else if (strpos($question, 'kontak') !== false || strpos($question, 'contact') !== false || 
         strpos($question, 'hubungi') !== false) {
    $response['type'] = 'contact_info';
    $response['message'] = "Berikut informasi kontak kami:";
    $response['contacts'] = [
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
    ];
}
// Tentang UMKM
else if (strpos($question, 'tentang') !== false || strpos($question, 'about') !== false || 
         strpos($question, 'profil') !== false) {
    $response['type'] = 'about';
    $response['message'] = "Tentang UMKM Batik Nusantara";
    $response['content'] = "UMKM Batik Nusantara didirikan pada tahun 2015 dengan tujuan melestarikan dan mempromosikan batik tradisional Indonesia. Kami memiliki komitmen untuk mendukung pengrajin batik lokal dan menjaga keaslian motif batik Indonesia.\n\nProduk kami meliputi berbagai jenis batik dari seluruh Indonesia termasuk Batik Solo, Batik Pekalongan, Batik Jogja, dan Batik Cirebon dengan desain modern maupun tradisional. Setiap produk dibuat dengan ketelitian tinggi dan menggunakan bahan berkualitas.";
}
// Menu bantuan
else if ($question == 'menu' || strpos($question, 'bantuan') !== false || strpos($question, 'help') !== false) {
    $response['type'] = 'help_menu';
    $response['message'] = "Berikut menu bantuan yang tersedia:";
    $response['menu'] = [
        "stok - Cara cek stok produk", 
        "bayar - Cara melakukan pembayaran", 
        "resi - Cara cek resi pengiriman",
        "kontak - Informasi kontak penjual",
        "tentang - Tentang UMKM Batik"
    ];
}
// Jika pertanyaan tidak dikenali
else {
    $response['type'] = 'unknown';
    $response['message'] = "Maaf, saya belum dapat memahami pertanyaan Anda. Silakan tanyakan tentang:\n\n1. Stok barang\n2. Cara pembayaran\n3. Cara cek resi\n4. Produk berdasarkan kategori\n5. Kontak kami\n6. Tentang UMKM\n\nAtau ketik 'menu' untuk melihat bantuan.";
}

// Fungsi untuk mengekstrak nama produk dari pertanyaan
function extractProductName($question) {
    // Simple extraction based on common patterns
    $patterns = [
        '/stok ([a-z0-9\s]+)/i',
        '/stock ([a-z0-9\s]+)/i',
        '/([a-z0-9\s]+) tersedia/i',
        '/ada ([a-z0-9\s]+)/i',
        '/ketersediaan ([a-z0-9\s]+)/i',
        '/cek ([a-z0-9\s]+)/i'
    ];
    
    foreach ($patterns as $pattern) {
        if (preg_match($pattern, $question, $matches)) {
            return trim($matches[1]);
        }
    }
    
    return null;
}

// Fungsi untuk mengekstrak nama kategori
function extractCategoryName($question) {
    $patterns = [
        '/kategori ([a-z0-9\s]+)/i',
        '/category ([a-z0-9\s]+)/i',
        '/produk ([a-z0-9\s]+)/i'
    ];
    
    foreach ($patterns as $pattern) {
        if (preg_match($pattern, $question, $matches)) {
            return trim($matches[1]);
        }
    }
    
    return null;
}

echo json_encode($response);
?>