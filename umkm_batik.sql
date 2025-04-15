-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost
-- Generation Time: Apr 14, 2025 at 06:48 AM
-- Server version: 8.0.30
-- PHP Version: 8.3.19

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `umkm_batik`
--

-- --------------------------------------------------------

--
-- Table structure for table `activity_logs`
--

CREATE TABLE `activity_logs` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `activity` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `activity_logs`
--

INSERT INTO `activity_logs` (`id`, `user_id`, `activity`, `created_at`) VALUES
(1, 3, 'Menambahkan ulasan untuk produk ID 1', '2025-03-19 15:34:43'),
(2, 4, 'Menambahkan ulasan untuk produk ID 2', '2025-03-19 15:34:43');

-- --------------------------------------------------------

--
-- Table structure for table `banners`
--

CREATE TABLE `banners` (
  `id` int NOT NULL,
  `image_url` varchar(255) DEFAULT NULL,
  `title` varchar(100) DEFAULT NULL,
  `description` text,
  `link` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `banners`
--

INSERT INTO `banners` (`id`, `image_url`, `title`, `description`, `link`, `created_at`) VALUES
(1, 'promo_batik.jpg', 'Diskon 20% untuk Semua Produk!', 'Jangan lewatkan diskon spesial untuk batik favorit Anda.', 'https://umkm-batik.com/promo', '2025-03-19 15:34:43');

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

CREATE TABLE `categories` (
  `id` int NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `categories`
--

INSERT INTO `categories` (`id`, `nama`, `created_at`) VALUES
(1, 'Batik Tulis', '2025-03-19 15:34:43'),
(2, 'Batik Cap', '2025-03-19 15:34:43'),
(3, 'Batik Kombinasi', '2025-03-19 15:34:43');

-- --------------------------------------------------------

--
-- Table structure for table `favorites`
--

CREATE TABLE `favorites` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `favorites`
--

INSERT INTO `favorites` (`id`, `user_id`, `product_id`, `created_at`) VALUES
(1, 3, 1, '2025-03-19 15:34:43'),
(2, 3, 2, '2025-03-19 15:34:43'),
(3, 4, 3, '2025-03-19 15:34:43');

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `message` text,
  `type` enum('order','promo','info') DEFAULT 'info',
  `is_read` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`id`, `user_id`, `message`, `type`, `is_read`, `created_at`) VALUES
(1, 3, 'Produk favorit Anda kembali tersedia!', 'info', 0, '2025-03-19 15:34:43'),
(2, 4, 'Promo diskon 20% untuk semua batik!', 'promo', 0, '2025-03-19 15:34:43');

--
-- Triggers `notifications`
--
DELIMITER $$
CREATE TRIGGER `save_notification_history` AFTER INSERT ON `notifications` FOR EACH ROW BEGIN
    INSERT INTO notification_history (user_id, message, type, created_at)
    VALUES (NEW.user_id, NEW.message, NEW.type, NOW());
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `notification_history`
--

CREATE TABLE `notification_history` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `message` text,
  `type` enum('order','promo','info') DEFAULT 'info',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `notification_history`
--

INSERT INTO `notification_history` (`id`, `user_id`, `message`, `type`, `created_at`) VALUES
(1, 3, 'Produk favorit Anda kembali tersedia!', 'info', '2025-03-19 15:34:43'),
(2, 4, 'Promo diskon 20% untuk semua batik!', 'promo', '2025-03-19 15:34:43');

-- --------------------------------------------------------

--
-- Table structure for table `price_history`
--

CREATE TABLE `price_history` (
  `id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `old_price` decimal(10,2) DEFAULT NULL,
  `new_price` decimal(10,2) DEFAULT NULL,
  `changed_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

CREATE TABLE `products` (
  `id` int NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `deskripsi` text,
  `harga` decimal(10,2) DEFAULT NULL,
  `stok` int DEFAULT NULL,
  `status` enum('available','out_of_stock','hidden') DEFAULT 'available',
  `rating` float DEFAULT '0',
  `whatsapp_link` varchar(255) DEFAULT NULL,
  `seller_id` int DEFAULT NULL,
  `category_id` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `products`
--

INSERT INTO `products` (`id`, `nama`, `deskripsi`, `harga`, `stok`, `status`, `rating`, `whatsapp_link`, `seller_id`, `category_id`, `created_at`) VALUES
(1, 'Batik Mega Mendung', 'Batik khas Cirebon dengan motif awan.', 250000.00, 10, 'available', 5, 'https://wa.me/6281234567891', 2, 1, '2025-03-19 15:34:43'),
(2, 'Batik Kawung', 'Motif khas Jawa Tengah dengan pola bulat.', 200000.00, 15, 'available', 4, 'https://wa.me/6281234567891', 2, 2, '2025-03-19 15:34:43'),
(3, 'Batik Parang', 'Motif bergelombang khas Keraton Yogyakarta.', 300000.00, 5, 'available', 4.8, 'https://wa.me/6281234567891', 2, 3, '2025-03-19 15:34:43');

--
-- Triggers `products`
--
DELIMITER $$
CREATE TRIGGER `track_price_change` BEFORE UPDATE ON `products` FOR EACH ROW BEGIN
    IF OLD.harga <> NEW.harga THEN
        INSERT INTO price_history (product_id, old_price, new_price, changed_at)
        VALUES (OLD.id, OLD.harga, NEW.harga, NOW());
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `product_images`
--

CREATE TABLE `product_images` (
  `id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `image_url` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `product_images`
--

INSERT INTO `product_images` (`id`, `product_id`, `image_url`) VALUES
(1, 1, 'mega_mendung_1.jpg'),
(2, 1, 'mega_mendung_2.jpg'),
(3, 2, 'kawung_1.jpg'),
(4, 2, 'kawung_2.jpg'),
(5, 3, 'parang_1.jpg'),
(6, 3, 'parang_2.jpg');

-- --------------------------------------------------------

--
-- Table structure for table `reviews`
--

CREATE TABLE `reviews` (
  `id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `rating` int DEFAULT NULL,
  `komentar` text,
  `is_verified` tinyint(1) DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ;

--
-- Dumping data for table `reviews`
--

INSERT INTO `reviews` (`id`, `product_id`, `user_id`, `rating`, `komentar`, `is_verified`, `created_at`) VALUES
(1, 1, 3, 5, 'Batiknya sangat bagus dan berkualitas!', 1, '2025-03-19 15:34:43'),
(2, 2, 4, 4, 'Motifnya menarik, tapi agak mahal.', 1, '2025-03-19 15:34:43');

--
-- Triggers `reviews`
--
DELIMITER $$
CREATE TRIGGER `log_user_activity` AFTER INSERT ON `reviews` FOR EACH ROW BEGIN
    INSERT INTO activity_logs (user_id, activity, created_at)
    VALUES (NEW.user_id, CONCAT('Menambahkan ulasan untuk produk ID ', NEW.product_id), NOW());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_product_rating` AFTER INSERT ON `reviews` FOR EACH ROW BEGIN
    UPDATE products
    SET rating = (SELECT AVG(rating) FROM reviews WHERE product_id = NEW.product_id)
    WHERE id = NEW.product_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `seller_reviews`
--

CREATE TABLE `seller_reviews` (
  `id` int NOT NULL,
  `seller_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `rating` int DEFAULT NULL,
  `komentar` text,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ;

-- --------------------------------------------------------

--
-- Table structure for table `stock_history`
--

CREATE TABLE `stock_history` (
  `id` int NOT NULL,
  `product_id` int DEFAULT NULL,
  `user_id` int DEFAULT NULL,
  `change_type` enum('increase','decrease') DEFAULT NULL,
  `amount` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Triggers `stock_history`
--
DELIMITER $$
CREATE TRIGGER `update_product_stock` AFTER INSERT ON `stock_history` FOR EACH ROW BEGIN
    IF NEW.change_type = 'increase' THEN
        UPDATE products SET stok = stok + NEW.amount WHERE id = NEW.product_id;
    ELSE
        UPDATE products SET stok = stok - NEW.amount WHERE id = NEW.product_id;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int NOT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `password` varchar(255) DEFAULT NULL,
  `no_hp` varchar(20) DEFAULT NULL,
  `role` enum('admin','seller','customer') DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `nama`, `email`, `password`, `no_hp`, `role`, `avatar`, `created_at`) VALUES
(1, 'Admin UMKM', 'admin@umkm.com', 'password_admin', '081234567890', 'admin', 'admin.jpg', '2025-03-19 15:34:43'),
(2, 'Batik Seller', 'seller@umkm.com', 'password_seller', '081234567891', 'seller', 'seller.jpg', '2025-03-19 15:34:43'),
(3, 'Customer 1', 'customer1@umkm.com', 'password_customer1', '081234567892', 'customer', 'customer1.jpg', '2025-03-19 15:34:43'),
(4, 'Customer 2', 'customer2@umkm.com', 'password_customer2', '081234567893', 'customer', 'customer2.jpg', '2025-03-19 15:34:43');

-- --------------------------------------------------------

--
-- Table structure for table `wishlist`
--

CREATE TABLE `wishlist` (
  `id` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `nama` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `wishlist`
--

INSERT INTO `wishlist` (`id`, `user_id`, `nama`, `created_at`) VALUES
(1, 3, 'Wishlist Saya', '2025-03-19 15:34:43'),
(2, 4, 'Wishlist Batik Favorit', '2025-03-19 15:34:43');

-- --------------------------------------------------------

--
-- Table structure for table `wishlist_items`
--

CREATE TABLE `wishlist_items` (
  `id` int NOT NULL,
  `wishlist_id` int DEFAULT NULL,
  `product_id` int DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Dumping data for table `wishlist_items`
--

INSERT INTO `wishlist_items` (`id`, `wishlist_id`, `product_id`) VALUES
(1, 1, 1),
(2, 1, 2),
(3, 2, 3);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `banners`
--
ALTER TABLE `banners`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `categories`
--
ALTER TABLE `categories`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nama` (`nama`);

--
-- Indexes for table `favorites`
--
ALTER TABLE `favorites`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `notification_history`
--
ALTER TABLE `notification_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `price_history`
--
ALTER TABLE `price_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `products`
--
ALTER TABLE `products`
  ADD PRIMARY KEY (`id`),
  ADD KEY `seller_id` (`seller_id`),
  ADD KEY `category_id` (`category_id`);

--
-- Indexes for table `product_images`
--
ALTER TABLE `product_images`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`);

--
-- Indexes for table `reviews`
--
ALTER TABLE `reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `seller_reviews`
--
ALTER TABLE `seller_reviews`
  ADD PRIMARY KEY (`id`),
  ADD KEY `seller_id` (`seller_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `stock_history`
--
ALTER TABLE `stock_history`
  ADD PRIMARY KEY (`id`),
  ADD KEY `product_id` (`product_id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- Indexes for table `wishlist`
--
ALTER TABLE `wishlist`
  ADD PRIMARY KEY (`id`),
  ADD KEY `user_id` (`user_id`);

--
-- Indexes for table `wishlist_items`
--
ALTER TABLE `wishlist_items`
  ADD PRIMARY KEY (`id`),
  ADD KEY `wishlist_id` (`wishlist_id`),
  ADD KEY `product_id` (`product_id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `activity_logs`
--
ALTER TABLE `activity_logs`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `banners`
--
ALTER TABLE `banners`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `categories`
--
ALTER TABLE `categories`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `favorites`
--
ALTER TABLE `favorites`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `notification_history`
--
ALTER TABLE `notification_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `price_history`
--
ALTER TABLE `price_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `products`
--
ALTER TABLE `products`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `product_images`
--
ALTER TABLE `product_images`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `reviews`
--
ALTER TABLE `reviews`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `seller_reviews`
--
ALTER TABLE `seller_reviews`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `stock_history`
--
ALTER TABLE `stock_history`
  MODIFY `id` int NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `wishlist`
--
ALTER TABLE `wishlist`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `wishlist_items`
--
ALTER TABLE `wishlist_items`
  MODIFY `id` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `activity_logs`
--
ALTER TABLE `activity_logs`
  ADD CONSTRAINT `activity_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `favorites`
--
ALTER TABLE `favorites`
  ADD CONSTRAINT `favorites_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `favorites_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `notification_history`
--
ALTER TABLE `notification_history`
  ADD CONSTRAINT `notification_history_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `price_history`
--
ALTER TABLE `price_history`
  ADD CONSTRAINT `price_history_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `products`
--
ALTER TABLE `products`
  ADD CONSTRAINT `products_ibfk_1` FOREIGN KEY (`seller_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `products_ibfk_2` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE SET NULL;

--
-- Constraints for table `product_images`
--
ALTER TABLE `product_images`
  ADD CONSTRAINT `product_images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `reviews`
--
ALTER TABLE `reviews`
  ADD CONSTRAINT `reviews_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `seller_reviews`
--
ALTER TABLE `seller_reviews`
  ADD CONSTRAINT `seller_reviews_ibfk_1` FOREIGN KEY (`seller_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `seller_reviews_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `stock_history`
--
ALTER TABLE `stock_history`
  ADD CONSTRAINT `stock_history_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `stock_history_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `wishlist`
--
ALTER TABLE `wishlist`
  ADD CONSTRAINT `wishlist_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `wishlist_items`
--
ALTER TABLE `wishlist_items`
  ADD CONSTRAINT `wishlist_items_ibfk_1` FOREIGN KEY (`wishlist_id`) REFERENCES `wishlist` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `wishlist_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
