<?php
require_once 'config.php';

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit(0);
}

// Cek apakah parameter `id` tersedia
if (!isset($_GET['id'])) {
    http_response_code(400);
    header("Content-Type: application/json");
    echo json_encode(['error' => 'Missing image id']);
    exit;
}

$imageId = intval($_GET['id']);

try {
    $conn = new PDO("mysql:host=$host;dbname=$database", $user, $password);
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Ambil gambar berdasarkan kolom `id` (bukan product_id)
    $stmt = $conn->prepare("SELECT image_product FROM product_images WHERE id = ? LIMIT 1");
    $stmt->execute([$imageId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row && $row['image_product']) {
        $imageData = $row['image_product'];

        // Deteksi tipe gambar
        $imageInfo = getimagesizefromstring($imageData);
        if ($imageInfo !== false) {
            $mimeType = $imageInfo['mime'];
        } else {
            $finfo = new finfo(FILEINFO_MIME_TYPE);
            $mimeType = $finfo->buffer($imageData);
            if (!$mimeType || $mimeType === 'application/octet-stream') {
                $mimeType = 'image/jpeg';
            }
        }

        // Tampilkan gambar
        header("Content-Type: " . $mimeType);
        header("Content-Length: " . strlen($imageData));
        header("Cache-Control: public, max-age=3600");
        header("Pragma: public");
        echo $imageData;

    } else {
        http_response_code(404);
        header("Content-Type: application/json");
        echo json_encode([
            'error' => 'Image not found',
            'image_id' => $imageId
        ]);
    }

} catch (PDOException $e) {
    http_response_code(500);
    header("Content-Type: application/json");
    echo json_encode([
        'error' => 'Database error',
        'message' => $e->getMessage()
    ]);
}
?>
