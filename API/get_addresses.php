<?php
// Turn off PHP's error display in favor of our own error handling
ini_set('display_errors', 0);
error_reporting(E_ALL);

// Set headers for CORS and response type
header("Content-Type: application/json");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
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

// Check if this is a GET request
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendError("Method not allowed. Please use GET.", 405);
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

// Get user_id from request
$user_id = isset($_GET['user_id']) ? (int)$_GET['user_id'] : null;

// Log the user_id received
fwrite($logFile, "Requested user_id: " . ($user_id !== null ? $user_id : "not provided") . "\n");

// Validate user_id
if ($user_id === null || $user_id <= 0) {
    sendError("Invalid or missing user_id parameter");
}

try {
    // Check if the addresses table exists
    $tableCheckQuery = "SHOW TABLES LIKE 'addresses'";
    $tableExists = $conn->query($tableCheckQuery);
    
    if ($tableExists->num_rows == 0) {
        sendError("Addresses table does not exist", 500);
    }
    
    // Prepare query to get addresses by user_id
    $sql = "SELECT * FROM addresses WHERE user_id = ?";
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        sendError("Failed to prepare query: " . $conn->error, 500);
    }
    
    $stmt->bind_param("i", $user_id);
    
    // Execute query
    if (!$stmt->execute()) {
        sendError("Failed to execute query: " . $stmt->error, 500);
    }
    
    // Get result
    $result = $stmt->get_result();
    
    // Check if any addresses were found
    if ($result->num_rows === 0) {
        // No addresses found for this user
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "No addresses found for this user",
            "data" => []
        ]);
    } else {
        // Addresses found, return them
        $addresses = [];
        while ($row = $result->fetch_assoc()) {
            $addresses[] = [
                "id" => $row["id"],
                "user_id" => $row["user_id"],
                "nama_lengkap" => $row["nama_lengkap"],
                "nomor_hp" => $row["nomor_hp"],
                "provinsi" => $row["provinsi"],
                "kota" => $row["kota"],
                "kecamatan" => $row["kecamatan"],
                "kode_pos" => $row["kode_pos"],
                "alamat_lengkap" => $row["alamat_lengkap"],
                "created_at" => $row["created_at"]
            ];
        }
        
        fwrite($logFile, "Found " . count($addresses) . " addresses for user_id: " . $user_id . "\n");
        
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Addresses retrieved successfully",
            "data" => $addresses
        ]);
    }
    
    // Close statement
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