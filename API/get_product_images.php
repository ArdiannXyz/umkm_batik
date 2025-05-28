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

        // Optimasi ukuran gambar jika parameter width disediakan
        if (isset($_GET['width']) && function_exists('imagecreatefromstring')) {
            $maxWidth = intval($_GET['width']);
            if ($maxWidth > 0 && $maxWidth <= 1200) { // Batasi max width
                $sourceImage = imagecreatefromstring($imageData);
                if ($sourceImage !== false) {
                    $origWidth = imagesx($sourceImage);
                    $origHeight = imagesy($sourceImage);
                    
                    if ($origWidth > $maxWidth) {
                        $ratio = $maxWidth / $origWidth;
                        $newHeight = $origHeight * $ratio;
                        
                        $resizedImage = imagecreatetruecolor($maxWidth, $newHeight);
                        imagecopyresampled(
                            $resizedImage, $sourceImage, 
                            0, 0, 0, 0, 
                            $maxWidth, $newHeight, $origWidth, $origHeight
                        );
                        
                        // Output gambar yang dioptimalkan
                        header("Content-Type: " . $mimeType);
                        if ($mimeType == 'image/jpeg') {
                            imagejpeg($resizedImage, null, 85); // kualitas 85%
                        } elseif ($mimeType == 'image/png') {
                            imagepng($resizedImage, null, 6); // kompresi level 6
                        }
                        
                        imagedestroy($sourceImage);
                        imagedestroy($resizedImage);
                        exit;
                    }
                    imagedestroy($sourceImage);
                }
            }
        }

        // Tambahkan Cache-Control header
        $maxAge = 86400; // 24 jam dalam detik
        header("Content-Type: " . $mimeType);
        header("Content-Length: " . strlen($imageData));
        header("Cache-Control: public, max-age=" . $maxAge);
        header("Expires: " . gmdate("D, d M Y H:i:s", time() + $maxAge) . " GMT");
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