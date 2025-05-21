<?php
// Turn off PHP's error display in favor of our own error handling
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Set header untuk CORS dan tipe response
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");

// Create a log file for debugging
$logFile = fopen("api_log.txt", "a");
fwrite($logFile, "-------------- " . date('Y-m-d H:i:s') . " --------------\n");
fwrite($logFile, "Request method: " . $_SERVER['REQUEST_METHOD'] . "\n");

// Function to send error response and log it
function sendError($message, $code = 400) {
    global $logFile;
    fwrite($logFile, "ERROR: $message\n");
    http_response_code($code);
    echo json_encode([
        "success" => false,
        "message" => $message
    ]);
    fwrite($logFile, "-------------- END --------------\n\n");
    fclose($logFile);
    exit;
}

// Tangani preflight request OPTIONS
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Check if this is a POST request
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError("Method not allowed. Please use POST.", 405);
}

// Attempt to include config file
try {
    // Check if file exists
    if (!file_exists('config.php')) {
        sendError("Configuration file missing", 500);
    }
    
    require_once 'config.php';
} catch (Exception $e) {
    sendError("Error loading configuration: " . $e->getMessage(), 500);
}

// Check if $conn is defined and is a valid mysqli connection
if (!isset($conn) || !($conn instanceof mysqli)) {
    sendError("Database connection not properly configured", 500);
}

// Periksa apakah koneksi database berhasil
if ($conn->connect_error) {
    sendError("Koneksi database gagal: " . $conn->connect_error, 500);
}

// Ambil dan validasi input JSON
$raw = file_get_contents("php://input");
fwrite($logFile, "Raw input: " . $raw . "\n");

if (empty($raw)) {
    sendError("No data received in request body");
}

// Try to decode JSON with error checking
$data = json_decode($raw, true);
$jsonError = json_last_error();

if ($jsonError !== JSON_ERROR_NONE) {
    sendError("Data tidak valid: " . json_last_error_msg());
}

// Log data yang diterima
fwrite($logFile, "Decoded data: " . print_r($data, true) . "\n");

// Pastikan semua field ada, termasuk user_id yang baru
$required_fields = ['user_id', 'nama_lengkap', 'nomor_hp', 'provinsi', 'kota', 'kecamatan', 'kode_pos', 'alamat_lengkap'];
$missing_fields = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field]) || trim($data[$field]) === '') {
        $missing_fields[] = $field;
    }
}

if (!empty($missing_fields)) {
    sendError("Field berikut tidak ditemukan atau kosong: " . implode(", ", $missing_fields));
}

// Check if database table exists
$tableCheckQuery = "SHOW TABLES LIKE 'addresses'";
$tableExists = $conn->query($tableCheckQuery);

if ($tableExists->num_rows == 0) {
    // Table doesn't exist, create it with user_id foreign key
    fwrite($logFile, "Table 'addresses' doesn't exist. Creating it...\n");
    
    $createTableSQL = "CREATE TABLE addresses (
        id INT AUTO_INCREMENT PRIMARY KEY,
        user_id INT NOT NULL,
        nama_lengkap VARCHAR(255) NOT NULL,
        nomor_hp VARCHAR(20) NOT NULL,
        provinsi VARCHAR(100) NOT NULL,
        kota VARCHAR(100) NOT NULL,
        kecamatan VARCHAR(100) NOT NULL,
        kode_pos VARCHAR(10) NOT NULL,
        alamat_lengkap TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    )";
    
    if (!$conn->query($createTableSQL)) {
        // If it fails because of the foreign key constraint, try creating without it first
        fwrite($logFile, "Error creating table with foreign key: " . $conn->error . "\n");
        fwrite($logFile, "Creating table without foreign key constraint...\n");
        
        $createTableSQL = "CREATE TABLE addresses (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            nama_lengkap VARCHAR(255) NOT NULL,
            nomor_hp VARCHAR(20) NOT NULL,
            provinsi VARCHAR(100) NOT NULL,
            kota VARCHAR(100) NOT NULL,
            kecamatan VARCHAR(100) NOT NULL,
            kode_pos VARCHAR(10) NOT NULL,
            alamat_lengkap TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )";
        
        if (!$conn->query($createTableSQL)) {
            sendError("Failed to create table: " . $conn->error, 500);
        }
        
        fwrite($logFile, "Table created without foreign key. Make sure the users table exists.\n");
    } else {
        fwrite($logFile, "Table 'addresses' created successfully with foreign key\n");
    }
} else {
    // Table exists, check if user_id column exists
    $columnCheckQuery = "SHOW COLUMNS FROM addresses LIKE 'user_id'";
    $columnExists = $conn->query($columnCheckQuery);
    
    if ($columnExists->num_rows == 0) {
        // Add user_id column
        fwrite($logFile, "Adding user_id column to addresses table\n");
        $alterTableSQL = "ALTER TABLE addresses ADD COLUMN user_id INT NOT NULL AFTER id";
        
        if (!$conn->query($alterTableSQL)) {
            sendError("Failed to add user_id column: " . $conn->error, 500);
        }
        
        // Try to add foreign key
        $addForeignKeySQL = "ALTER TABLE addresses ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE";
        $conn->query($addForeignKeySQL); // We don't stop if this fails, just log it
        
        if ($conn->error) {
            fwrite($logFile, "Warning: Could not add foreign key constraint: " . $conn->error . "\n");
            fwrite($logFile, "Make sure the users table exists with an id primary key.\n");
        } else {
            fwrite($logFile, "Foreign key constraint added successfully\n");
        }
    }
}

try {
    // Persiapkan dan bersihkan data untuk mencegah SQL injection
    $user_id = (int)$data['user_id']; // Cast to integer for safety
    $nama_lengkap = $data['nama_lengkap'];
    $nomor_hp = $data['nomor_hp'];
    $provinsi = $data['provinsi'];
    $kota = $data['kota'];
    $kecamatan = $data['kecamatan'];
    $kode_pos = $data['kode_pos'];
    $alamat_lengkap = $data['alamat_lengkap'];

    // Simpan ke DB dengan user_id
    $sql = "INSERT INTO addresses (user_id, nama_lengkap, nomor_hp, provinsi, kota, kecamatan, kode_pos, alamat_lengkap)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
            
    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        sendError("Gagal mempersiapkan query: " . $conn->error, 500);
    }

    $stmt->bind_param(
        "isssssss",
        $user_id,
        $nama_lengkap,
        $nomor_hp,
        $provinsi,
        $kota,
        $kecamatan,
        $kode_pos,
        $alamat_lengkap
    );

    // Eksekusi query dan tangani hasilnya
    if ($stmt->execute()) {
        fwrite($logFile, "Insert successful. New ID: " . $conn->insert_id . "\n");
        
        http_response_code(200);
        echo json_encode([
            "success" => true, 
            "message" => "Alamat berhasil disimpan",
            "id" => $conn->insert_id
        ]);
    } else {
        sendError("Gagal menyimpan alamat: " . $stmt->error, 500);
    }

    // Tutup koneksi
    $stmt->close();
} catch (Exception $e) {
    sendError("Error processing request: " . $e->getMessage(), 500);
} finally {
    // Always close connection
    if (isset($conn)) {
        $conn->close();
    }
    
    fwrite($logFile, "-------------- END --------------\n\n");
    fclose($logFile);
}
?>