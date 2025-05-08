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
$logFile = fopen("check_review_log.txt", "a");
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

// Pastikan semua field ada
$required_fields = ['product_id', 'user_id'];
$missing_fields = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field])) {
        $missing_fields[] = $field;
    }
}

if (!empty($missing_fields)) {
    sendError("Field berikut tidak ditemukan: " . implode(", ", $missing_fields));
}

// Persiapkan dan bersihkan data untuk mencegah SQL injection
$product_id = (int)$data['product_id'];
$user_id = (int)$data['user_id'];

try {
    // Check if reviews table exists
    $tableCheckQuery = "SHOW TABLES LIKE 'reviews'";
    $tableExists = $conn->query($tableCheckQuery);
    
    if ($tableExists->num_rows == 0) {
        // Table doesn't exist yet, so user hasn't reviewed
        fwrite($logFile, "Reviews table doesn't exist yet\n");
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "has_reviewed" => false
        ]);
        exit;
    }
    
    // Cek apakah user sudah memberikan ulasan untuk produk ini dan ambil datanya jika ada
    $sql = "SELECT * FROM reviews WHERE user_id = ? AND product_id = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        sendError("Gagal mempersiapkan query: " . $conn->error, 500);
    }
    
    $stmt->bind_param("ii", $user_id, $product_id);
    
    if (!$stmt->execute()) {
        sendError("Gagal menjalankan query: " . $stmt->error, 500);
    }
    
    $result = $stmt->get_result();
    $has_reviewed = $result->num_rows > 0;
    
    fwrite($logFile, "Has reviewed: " . ($has_reviewed ? "Yes" : "No") . "\n");
    
    // Response data
    $response = [
        "success" => true,
        "has_reviewed" => $has_reviewed
    ];
    
    // Jika user sudah memberikan ulasan, tambahkan data ulasan ke response
    if ($has_reviewed) {
        $review_data = $result->fetch_assoc();
        $response["review_data"] = $review_data;
        fwrite($logFile, "Review data: " . print_r($review_data, true) . "\n");
    }
    
    http_response_code(200);
    echo json_encode($response);
    
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