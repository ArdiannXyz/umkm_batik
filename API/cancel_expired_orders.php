<?php
// Database connection configuration
require_once 'config.php';

// This script should be run as a cron job every few minutes

// Set timeout period (in hours)
$paymentTimeoutHours = 24;

// Find orders with expired payment deadline
$query = "UPDATE umkm_batik.orders o
          JOIN umkm_batik.payments p ON o.id = p.order_id
          SET o.status = 'cancelled', 
              p.status_pembayaran = 'failed'
          WHERE o.status = 'pending' 
          AND p.status_pembayaran = 'pending'
          AND o.waktu_order < DATE_SUB(NOW(), INTERVAL ? HOUR)";

$stmt = $conn->prepare($query);
$stmt->bind_param("i", $paymentTimeoutHours);
$stmt->execute();

$cancelledCount = $stmt->affected_rows;

// Return stock for cancelled orders
if ($cancelledCount > 0) {
    // Get all items from cancelled orders to restore stock
    $itemsQuery = "SELECT oi.product_id, oi.kuantitas, p.stok_id 
                  FROM umkm_batik.orders o
                  JOIN umkm_batik.order_items oi ON o.id = oi.order_id
                  JOIN umkm_batik.products p ON oi.product_id = p.id
                  WHERE o.status = 'cancelled'
                  AND o.updated_at IS NULL OR o.updated_at = o.created_at";
                  
    $itemsResult = $conn->query($itemsQuery);
    
    while ($item = $itemsResult->fetch_assoc()) {
        // Restore stock quantity
        $updateStockQuery = "UPDATE umkm_batik.stocks 
                           SET quantity = quantity + ? 
                           WHERE id = ?";
        
        $updateStmt = $conn->prepare($updateStockQuery);
        $updateStmt->bind_param("ii", $item['kuantitas'], $item['stok_id']);
        $updateStmt->execute();
        
        // Update product status if necessary
        $checkProductQuery = "UPDATE umkm_batik.products 
                            SET status = 'available' 
                            WHERE id = ? 
                            AND status = 'out_of_stock'";
        
        $checkStmt = $conn->prepare($checkProductQuery);
        $checkStmt->bind_param("i", $item['product_id']);
        $checkStmt->execute();
    }
    
    // Update the updated_at timestamp for processed cancelled orders
    $updateTimestampQuery = "UPDATE umkm_batik.orders 
                           SET updated_at = NOW() 
                           WHERE status = 'cancelled' 
                           AND (updated_at IS NULL OR updated_at = created_at)";
    
    $conn->query($updateTimestampQuery);
    
    echo "Cancelled $cancelledCount expired orders and restored stock.\n";
} else {
    echo "No expired orders found.\n";
}

// Close connection
$conn->close();
?>