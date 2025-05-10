<?php
// Turn off PHP's error display in favor of our own error handling
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Set headers for CORS and response type
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

// Handle preflight OPTIONS request
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

// Check if database connection is successful
if ($conn->connect_error) {
    sendError("Database connection failed: " . $conn->connect_error, 500);
}

// Get and validate input JSON
$raw = file_get_contents("php://input");
fwrite($logFile, "Raw input: " . $raw . "\n");

if (empty($raw)) {
    sendError("No data received in request body");
}

// Try to decode JSON with error checking
$data = json_decode($raw, true);
$jsonError = json_last_error();

if ($jsonError !== JSON_ERROR_NONE) {
    sendError("Invalid data format: " . json_last_error_msg());
}

// Log data received
fwrite($logFile, "Decoded data: " . print_r($data, true) . "\n");

// Ensure all required fields are present
$required_fields = ['id', 'user_id', 'nama_lengkap', 'nomor_hp', 'provinsi', 'kota', 'kecamatan', 'kode_pos', 'alamat_lengkap'];
$missing_fields = [];

foreach ($required_fields as $field) {
    if (!isset($data[$field]) || trim($data[$field]) === '') {
        $missing_fields[] = $field;
    }
}

if (!empty($missing_fields)) {
    sendError("The following fields are missing or empty: " . implode(", ", $missing_fields));
}

try {
    // Prepare and sanitize data to prevent SQL injection
    $id = (int)$data['id'];
    $user_id = (int)$data['user_id'];
    $nama_lengkap = $data['nama_lengkap'];
    $nomor_hp = $data['nomor_hp'];
    $provinsi = $data['provinsi'];
    $kota = $data['kota'];
    $kecamatan = $data['kecamatan'];
    $kode_pos = $data['kode_pos'];
    $alamat_lengkap = $data['alamat_lengkap'];

    // First verify that the address belongs to the specified user
    $verifySQL = "SELECT id FROM addresses WHERE id = ? AND user_id = ? LIMIT 1";
    $verifyStmt = $conn->prepare($verifySQL);
    
    if (!$verifyStmt) {
        sendError("Failed to prepare verification query: " . $conn->error, 500);
    }
    
    $verifyStmt->bind_param("ii", $id, $user_id);
    $verifyStmt->execute();
    $verifyResult = $verifyStmt->get_result();
    
    if ($verifyResult->num_rows === 0) {
        sendError("Address not found or you don't have permission to edit it", 403);
    }
    
    $verifyStmt->close();

    // Proceed with update
    $sql = "UPDATE addresses SET 
            nama_lengkap = ?, 
            nomor_hp = ?, 
            provinsi = ?, 
            kota = ?, 
            kecamatan = ?, 
            kode_pos = ?, 
            alamat_lengkap = ? 
            WHERE id = ? AND user_id = ?";
            
    $stmt = $conn->prepare($sql);

    if (!$stmt) {
        sendError("Failed to prepare update query: " . $conn->error, 500);
    }

    $stmt->bind_param(
        "sssssssii",
        $nama_lengkap,
        $nomor_hp,
        $provinsi,
        $kota,
        $kecamatan,
        $kode_pos,
        $alamat_lengkap,
        $id,
        $user_id
    );

    // Execute query and handle result
    if ($stmt->execute()) {
        // Check if any rows were affected (updated)
        if ($stmt->affected_rows > 0) {
            fwrite($logFile, "Update successful for address ID: $id\n");
            
            http_response_code(200);
            echo json_encode([
                "success" => true, 
                "message" => "Alamat berhasil diperbarui"
            ]);
        } else {
            // No rows were updated (might be because the data is the same)
            fwrite($logFile, "No changes made to address ID: $id\n");
            
            http_response_code(200);
            echo json_encode([
                "success" => true,
                "message" => "Tidak ada perubahan pada alamat"
            ]);
        }
    } else {
        sendError("Failed to update address: " . $stmt->error, 500);
    }

    // Close statement
    $stmt->close();
} catch (Exception $e) {
    sendError("Error processing request: " . $e->getMessage(), 500);
} finally {
    // Always close the connection
    if (isset($conn)) {
        $conn->close();
    }
    
    fwrite($logFile, "-------------- END --------------\n\n");
    fclose($logFile);
}
?>