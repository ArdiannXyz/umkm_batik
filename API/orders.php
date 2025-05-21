<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

// Add these headers at the very beginning
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Log incoming requests for debugging
error_log("Method: " . $_SERVER['REQUEST_METHOD']);
error_log("Raw input: " . file_get_contents("php://input"));

// Create Database wrapper class to use PDO with your existing config
class Database {
    private $conn;
    
    public function __construct() {
        global $host, $user, $password, $database;
        
        try {
            $this->conn = new PDO(
                "mysql:host=" . $host . ";dbname=" . $database,
                $user,
                $password,
                array(PDO::MYSQL_ATTR_INIT_COMMAND => "SET NAMES utf8")
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $exception) {
            error_log("Connection error: " . $exception->getMessage());
            throw $exception;
        }
    }
    
    public function getConnection() {
        return $this->conn;
    }
}

// Order model class with improved error handling
class Order {
    private $conn;
    private $table = 'orders';
    
    public function __construct($db) {
        $this->conn = $db;
    }
    
    // Get orders by user ID and status
    public function getOrdersByUserAndStatus($user_id, $status) {
        $query = "SELECT * FROM " . $this->table . " 
                  WHERE user_id = :user_id AND status = :status 
                  ORDER BY waktu_order DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':status', $status);
        $stmt->execute();
        
        return $stmt;
    }
    
    // Get all orders for a user
    public function getAllOrdersByUser($user_id) {
        $query = "SELECT * FROM " . $this->table . " 
                  WHERE user_id = :user_id
                  ORDER BY waktu_order DESC";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->execute();
        
        return $stmt;
    }
    
    // Get order details with items
    public function getOrderDetails($order_id, $user_id) {
        try {
            // Get order info
            $query = "SELECT * FROM " . $this->table . " 
                      WHERE id = :order_id AND user_id = :user_id";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':order_id', $order_id);
            $stmt->bindParam(':user_id', $user_id);
            $stmt->execute();
            
            $order = $stmt->fetch(PDO::FETCH_ASSOC);
            
            if(!$order) {
                return null;
            }
            
            // Get order items with product details and images
            $query = "SELECT oi.*, p.nama, p.deskripsi, 
                    (SELECT CONCAT('/get_product_images.php?id=', pi.id) 
                    FROM product_images pi 
                    WHERE pi.product_id = p.id AND pi.is_main = 1 
                    LIMIT 1) as image_url
                    FROM order_items oi 
                    JOIN products p ON oi.product_id = p.id 
                    WHERE oi.order_id = :order_id";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':order_id', $order_id);
            $stmt->execute();
            
            $order['items'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Get payment info if available
            $query = "SELECT * FROM payments WHERE order_id = :order_id";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':order_id', $order_id);
            $stmt->execute();
            
            $payment = $stmt->fetch(PDO::FETCH_ASSOC);
            if($payment) {
                $order['payment'] = $payment;
            }
            
            // Get shipping info if available
            $query = "SELECT * FROM pengiriman WHERE order_id = :order_id";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':order_id', $order_id);
            $stmt->execute();
            
            $shipping = $stmt->fetch(PDO::FETCH_ASSOC);
            if($shipping) {
                $order['shipping'] = $shipping;
            }
            
            return $order;
        } catch (Exception $e) {
            error_log("Error in getOrderDetails: " . $e->getMessage());
            return null;
        }
    }
    
    // Complete order - update both order and payment status
    public function completeOrder($order_id, $user_id = null) {
        try {
            $this->conn->beginTransaction();
            
            // Verify order belongs to user if user_id provided
            if ($user_id) {
                $query = "SELECT id, status FROM " . $this->table . " WHERE id = :order_id AND user_id = :user_id";
                $stmt = $this->conn->prepare($query);
                $stmt->bindParam(':order_id', $order_id);
                $stmt->bindParam(':user_id', $user_id);
                $stmt->execute();
                
                $orderInfo = $stmt->fetch(PDO::FETCH_ASSOC);
                if (!$orderInfo) {
                    throw new Exception("Order not found or access denied");
                }
                
                // Check if order is already completed
                if ($orderInfo['status'] === 'completed') {
                    throw new Exception("Order is already completed");
                }
            }
            
            // Update order status to completed
        $query = "UPDATE pengiriman 
                 SET status_pengiriman = 'sampai', 
                     tanggal_sampai = NOW() 
                 WHERE order_id = :order_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->execute();
            
            if (!$stmt->execute()) {
                throw new Exception("Failed to update order status");
            }
            
            // Check if any rows were affected
            if ($stmt->rowCount() === 0) {
                throw new Exception("No order found with the given ID");
            }
            
            // Update payment status to completed (if payment exists)
            $query = "UPDATE payments SET status_pembayaran = 'completed' WHERE order_id = :order_id";
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':order_id', $order_id, PDO::PARAM_INT);
            $stmt->execute(); // Don't throw error if no payment exists
            
            // Update shipping status to sampai (if shipping exists)
            $query = "UPDATE pengiriman SET status_pengiriman = 'sampai' WHERE order_id = :order_id";
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':order_id', $order_id, PDO::PARAM_INT);
            $stmt->execute(); // Don't throw error if no shipping exists
            
            $this->conn->commit();
            return true;
            
        } catch (Exception $e) {
            $this->conn->rollBack();
            error_log("Error in completeOrder: " . $e->getMessage());
            throw $e;
        }
    }
    
    // Create a new order
    public function createOrder($user_id, $alamat_pemesanan, $metode_pengiriman, $notes) {
        $query = "INSERT INTO " . $this->table . " 
                 (user_id, waktu_order, status, alamat_pemesanan, metode_pengiriman, notes, created_at) 
                 VALUES 
                 (:user_id, NOW(), 'pending', :alamat_pemesanan, :metode_pengiriman, :notes, NOW())";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':user_id', $user_id);
        $stmt->bindParam(':alamat_pemesanan', $alamat_pemesanan);
        $stmt->bindParam(':metode_pengiriman', $metode_pengiriman);
        $stmt->bindParam(':notes', $notes);
        
        if($stmt->execute()) {
            return $this->conn->lastInsertId();
        }
        
        return false;
    }
    
    // Add items to an order
    public function addOrderItems($order_id, $items) {
        $total_harga = 0;
        
        foreach($items as $item) {
            $subtotal = $item['harga'] * $item['kuantitas'];
            $total_harga += $subtotal;
            
            $query = "INSERT INTO order_items 
                      (order_id, product_id, kuantitas, harga, subtotal) 
                      VALUES 
                      (:order_id, :product_id, :kuantitas, :harga, :subtotal)";
            
            $stmt = $this->conn->prepare($query);
            $stmt->bindParam(':order_id', $order_id);
            $stmt->bindParam(':product_id', $item['product_id']);
            $stmt->bindParam(':kuantitas', $item['kuantitas']);
            $stmt->bindParam(':harga', $item['harga']);
            $stmt->bindParam(':subtotal', $subtotal);
            
            $stmt->execute();
        }
        
        // Update order total
        $query = "UPDATE " . $this->table . " SET total_harga = :total_harga WHERE id = :order_id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':total_harga', $total_harga);
        $stmt->bindParam(':order_id', $order_id);
        
        return $stmt->execute();
    }
    
    // Add payment for an order
    public function addPayment($order_id, $metode_pembayaran) {
        $query = "INSERT INTO payments 
                 (order_id, metode_pembayaran, status_pembayaran, waktu_pembayaran) 
                 VALUES 
                 (:order_id, :metode_pembayaran, 'pending', NOW())";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':order_id', $order_id);
        $stmt->bindParam(':metode_pembayaran', $metode_pembayaran);
        
        return $stmt->execute();
    }
    
public function addOrUpdateShipping($order_id, $nomor_resi, $jasa_kurir, $status_pengiriman = 'dikirim', $catatan = null) {
    // Check if shipping record exists
    $query = "SELECT id FROM pengiriman WHERE order_id = :order_id";
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':order_id', $order_id);
    $stmt->execute();
    
    if($stmt->rowCount() > 0) {
        // Update existing record - PERUBAHAN DI SINI
        $query = "UPDATE pengiriman 
                  SET nomor_resi = :nomor_resi, 
                      jasa_kurir = :jasa_kurir, 
                      status_pengiriman = :status_pengiriman,
                      tanggal_dikirim = CASE WHEN :status_pengiriman = 'dikirim' THEN NOW() ELSE tanggal_dikirim END,
                      tanggal_sampai = CASE WHEN :status_pengiriman = 'sampai' THEN NOW() ELSE tanggal_sampai END,
                      catatan = COALESCE(:catatan, catatan)
                  WHERE order_id = :order_id";
    } else {
        // Create new record - PERUBAHAN DI SINI
        $query = "INSERT INTO pengiriman 
                 (order_id, nomor_resi, jasa_kurir, status_pengiriman, tanggal_dikirim, catatan, created_at) 
                 VALUES 
                 (:order_id, :nomor_resi, :jasa_kurir, :status_pengiriman, 
                  CASE WHEN :status_pengiriman = 'dikirim' THEN NOW() ELSE NULL END, 
                  :catatan, NOW())";
    }
    
    $stmt = $this->conn->prepare($query);
    $stmt->bindParam(':order_id', $order_id);
    $stmt->bindParam(':nomor_resi', $nomor_resi);
    $stmt->bindParam(':jasa_kurir', $jasa_kurir);
    $stmt->bindParam(':status_pengiriman', $status_pengiriman);
    $stmt->bindParam(':catatan', $catatan);
    
    return $stmt->execute();
}
    
    // Update order status
    public function updateStatus($order_id, $status) {
        $query = "UPDATE " . $this->table . " SET status = :status WHERE id = :order_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':status', $status);
        $stmt->bindParam(':order_id', $order_id);
        
        return $stmt->execute();
    }
    
    // Update payment status
    public function updatePaymentStatus($order_id, $status) {
        $query = "UPDATE payments SET status_pembayaran = :status WHERE order_id = :order_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':status', $status);
        $stmt->bindParam(':order_id', $order_id);
        
        return $stmt->execute();
    }
    
    // Update shipping status
    public function updateShippingStatus($order_id, $status) {
        $query = "UPDATE pengiriman SET status_pengiriman = :status WHERE order_id = :order_id";
        
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':status', $status);
        $stmt->bindParam(':order_id', $order_id);
        
        return $stmt->execute();
    }
    
    // Map status values for UI display
    public static function mapStatusForUI($dbStatus) {
        switch($dbStatus) {
            case 'pending':
                return 'Belum bayar';
            case 'paid':
                return 'Dibayar';
            case 'shipped':
                return 'Dikirim';
            case 'completed':
                return 'Selesai';
            case 'cancelled':
                return 'Batal';
            default:
                return 'Unknown';
        }
    }
    
    // Map status values from UI to database
    public static function mapStatusForDB($uiStatus) {
        switch($uiStatus) {
            case 'Belum bayar':
                return 'pending';
            case 'Dibayar':
                return 'paid';
            case 'Dikirim':
                return 'shipped';
            case 'Selesai':
                return 'completed';
            case 'Batal':
                return 'cancelled';
            default:
                return 'pending';
        }
    }
    
    // Map shipping status values for UI display
    public static function mapShippingStatusForUI($dbStatus) {
        switch($dbStatus) {
            case 'diproses':
                return 'Diproses';
            case 'dikirim':
                return 'Dalam Pengiriman';
            case 'dalam_perjalanan':
                return 'Dalam Perjalanan';
            case 'sampai':
                return 'Sampai Tujuan';
            case 'gagal':
                return 'Gagal';
            default:
                return 'Unknown';
        }
    }
}

try {
    // Initialize database connection
    $database = new Database();
    $db = $database->getConnection();
    $order = new Order($db);

    // Get request method
    $method = $_SERVER['REQUEST_METHOD'];

    // Process based on request method
    switch($method) {
        case 'GET':
            // Ambil dan validasi user_id
            if (!isset($_GET['user_id']) || !ctype_digit($_GET['user_id'])) {
                http_response_code(400);
                exit(json_encode(['status'=>'error','message'=>'user_id required']));
            }
            $user_id = (int) $_GET['user_id'];

            // Cek apakah minta detail spesifik
            if (isset($_GET['order_id'])) {
                $order_id = (int) $_GET['order_id'];
                $details = $order->getOrderDetails($order_id, $user_id);
                if (!$details) {
                    http_response_code(404);
                    exit(json_encode(['status'=>'error','message'=>'Order not found']));
                }
                $details['status_display'] = Order::mapStatusForUI($details['status']);
                
                // Add shipping status display if shipping exists
                if (isset($details['shipping']) && isset($details['shipping']['status_pengiriman'])) {
                    $details['shipping']['status_display'] = Order::mapShippingStatusForUI($details['shipping']['status_pengiriman']);
                }
                
                exit(json_encode(['status'=>'success','data'=>$details]));
            }

            // Cek apakah ada filter status yang non‑kosong
            $orders = [];
            if (isset($_GET['status']) && trim($_GET['status']) !== '') {
                $status_db = Order::mapStatusForDB($_GET['status']);
                $stmt = $order->getOrdersByUserAndStatus($user_id, $status_db);
            } else {
                $stmt = $order->getAllOrdersByUser($user_id);
            }

            $orders = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Fix: Make sure we have at least an empty array to avoid index errors
            if (empty($orders)) {
                exit(json_encode(['status'=>'success','data'=>[]]));
            }
            
            // Lampirkan items + status_display ke setiap order
            foreach ($orders as &$o) {
                $o['status_display'] = Order::mapStatusForUI($o['status']);
                $itemStmt = $db->prepare(
                    "SELECT oi.*, p.nama, p.deskripsi,
                     (SELECT CONCAT('/get_main_product_images.php?id=', pi.id) 
                      FROM product_images pi 
                      WHERE pi.product_id = p.id AND pi.is_main = 1 
                      LIMIT 1) as image_url
                     FROM order_items oi
                     JOIN products p ON p.id = oi.product_id
                     WHERE oi.order_id = :oid"
                );
                $itemStmt->execute([':oid'=>$o['id']]);
                $o['items'] = $itemStmt->fetchAll(PDO::FETCH_ASSOC);
                
                // Add shipping info if available
                $shippingStmt = $db->prepare(
                    "SELECT * FROM pengiriman WHERE order_id = :oid"
                );
                $shippingStmt->execute([':oid'=>$o['id']]);
                $shipping = $shippingStmt->fetch(PDO::FETCH_ASSOC);
                if ($shipping) {
                    $shipping['status_display'] = Order::mapShippingStatusForUI($shipping['status_pengiriman']);
                    $o['shipping'] = $shipping;
                }
            }

            exit(json_encode(['status'=>'success','data'=>$orders]));
            break;
        
        case 'POST':
            // Get posted data
            $input = file_get_contents("php://input");
            $data = json_decode($input, true);
            
            if (json_last_error() !== JSON_ERROR_NONE) {
                http_response_code(400);
                exit(json_encode(['status' => 'error', 'message' => 'Invalid JSON data: ' . json_last_error_msg()]));
            }
            
            error_log("Received data: " . print_r($data, true));
            
            // Create new order
            if(isset($data['user_id']) && isset($data['items']) && 
               isset($data['alamat_pemesanan']) && isset($data['metode_pengiriman'])) {
                
                $user_id = $data['user_id'];
                $alamat_pemesanan = $data['alamat_pemesanan'];
                $metode_pengiriman = $data['metode_pengiriman'];
                $notes = isset($data['notes']) ? $data['notes'] : '';
                $items = $data['items'];
                $metode_pembayaran = isset($data['metode_pembayaran']) ? $data['metode_pembayaran'] : null;
                
                // Start transaction
                $db->beginTransaction();
                
                try {
                    // Create order
                    $order_id = $order->createOrder($user_id, $alamat_pemesanan, $metode_pengiriman, $notes);
                    
                    if($order_id) {
                        // Add order items
                        if($order->addOrderItems($order_id, $items)) {
                            // Add payment if method provided
                            if($metode_pembayaran) {
                                $order->addPayment($order_id, $metode_pembayaran);
                            }
                            
                            $db->commit();
                            
                            echo json_encode([
                                'status' => 'success', 
                                'message' => 'Order created successfully', 
                                'order_id' => $order_id
                            ]);
                        } else {
                            throw new Exception("Failed to add order items");
                        }
                    } else {
                        throw new Exception("Failed to create order");
                    }
                } catch (Exception $e) {
                    $db->rollBack();
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
                }
            }
            // Complete order (mark as completed)
            // ... kode sebelumnya ...

elseif(isset($data['order_id']) && isset($data['nomor_resi']) && isset($data['jasa_kurir'])) {
    $order_id = (int) $data['order_id'];
    $nomor_resi = $data['nomor_resi'];
    $jasa_kurir = $data['jasa_kurir'];
    // PERUBAHAN DI SINI - Tambah parameter baru
    $status_pengiriman = isset($data['status_pengiriman']) ? $data['status_pengiriman'] : 'dikirim';
    $catatan = isset($data['catatan']) ? $data['catatan'] : null;
    
    try {
        if ($order->addOrUpdateShipping($order_id, $nomor_resi, $jasa_kurir, $status_pengiriman, $catatan)) {
            // PERUBAHAN DI SINI - Logika update status order
            $order_status_mapping = [
                'diproses' => 'paid',
                'dikirim' => 'shipped',
                'dalam_perjalanan' => 'shipped',
                'sampai' => 'completed',
                'gagal' => 'cancelled'
            ];
            
            $order_status = $order_status_mapping[$status_pengiriman] ?? 'paid';
            $order->updateStatus($order_id, $order_status);
            
            echo json_encode([
                'status' => 'success', 
                'message' => 'Informasi pengiriman diperbarui',
                'data' => [
                    'order_status' => $order_status,
                    'shipping_status' => $status_pengiriman
                ]
            ]);
        } else {
            http_response_code(500);
            echo json_encode(['status' => 'error', 'message' => 'Gagal memperbarui informasi pengiriman']);
        }
    } catch (Exception $e) {
        http_response_code(500);
        echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
    }
}

// ... kode setelahnya ...
            // Add or update shipping information
            elseif(isset($data['order_id']) && isset($data['nomor_resi']) && isset($data['jasa_kurir'])) {
                $order_id = (int) $data['order_id'];
                $nomor_resi = $data['nomor_resi'];
                $jasa_kurir = $data['jasa_kurir'];
                
                try {
                    if ($order->addOrUpdateShipping($order_id, $nomor_resi, $jasa_kurir)) {
                        // Also update the order status to shipped if needed
                        $order->updateStatus($order_id, 'shipped');
                        echo json_encode(['status' => 'success', 'message' => 'Shipping information updated successfully']);
                    } else {
                        http_response_code(500);
                        echo json_encode(['status' => 'error', 'message' => 'Failed to update shipping information']);
                    }
                } catch (Exception $e) {
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => $e->getMessage()]);
                }
            }
            // Update order status (general)
            elseif(isset($data['order_id']) && isset($data['status'])) {
                $order_id = $data['order_id'];
                $status = $data['status'];
                
                if($order->updateStatus($order_id, $status)) {
                    echo json_encode(['status' => 'success', 'message' => 'Order status updated']);
                } else {
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => 'Failed to update order status']);
                }
            }
            // Update payment status
            elseif(isset($data['order_id']) && isset($data['payment_status'])) {
                $order_id = $data['order_id'];
                $status = $data['payment_status'];
                
                if($order->updatePaymentStatus($order_id, $status)) {
                    echo json_encode(['status' => 'success', 'message' => 'Payment status updated']);
                } else {
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => 'Failed to update payment status']);
                }
            }
            // Update shipping status
            elseif(isset($data['order_id']) && isset($data['shipping_status'])) {
                $order_id = $data['order_id'];
                $status = $data['shipping_status'];
                
                if($order->updateShippingStatus($order_id, $status)) {
                    echo json_encode(['status' => 'success', 'message' => 'Shipping status updated']);
                } else {
                    http_response_code(500);
                    echo json_encode(['status' => 'error', 'message' => 'Failed to update shipping status']);
                }
            }
            else {
                http_response_code(400);
                echo json_encode(['status' => 'error', 'message' => 'Missing required parameters']);
            }
            break;
            
        default:
            http_response_code(405);
            echo json_encode(['status' => 'error', 'message' => 'Method not allowed']);
            break;
    }
} catch (Exception $e) {
    error_log("Fatal error: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['status' => 'error', 'message' => 'Internal server error']);
}
?>