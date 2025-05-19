// product_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/product_image.dart';

const String baseUrl = 'http://localhost/umkm_batik/API/';

class ProductService {
  static Future<List<Product>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_products.php'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          return (jsonResponse['data'] as List)
              .map((item) => Product.fromJson(item))
              .toList();
        } else {
          print('Gagal: ${jsonResponse['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception saat ambil produk: $e');
    }
    return [];
  }

  static Future<Product?> fetchProductDetail(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_product_detail.php?id=$productId'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success']) {
          return Product.fromJson(jsonResponse['data']);
        } else {
          print('Gagal: ${jsonResponse['message']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception saat ambil detail produk: $e');
    }
    return null;
  }

  static Future<List<ProductImage>> fetchProductImages(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}get_product_images.php?product_id=$productId'),
      );

      if (response.statusCode == 200) {
        final List jsonResponse = jsonDecode(response.body);
        return jsonResponse.map((item) => ProductImage.fromJson(item)).toList();
      } else {
        print('HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception saat ambil gambar produk: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> sendChatMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chatbot_api.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': message}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      // Jika server tidak tersedia atau error, gunakan respons offline
      return getOfflineResponse(message);
    }
  }

  // Fungsi respons offline (jika API tidak tersedia)
  static Map<String, dynamic> getOfflineResponse(String message) {
    message = message.toLowerCase();

    // Cek stok
    if (message.contains('stok') || message.contains('stock')) {
      return {
        'type': 'stock_steps',
        'message':
            'Untuk memeriksa stok barang, silakan ikuti langkah-langkah berikut:',
        'steps': [
          "1. Buka halaman utama aplikasi",
          "2. Gunakan fitur pencarian di bagian atas untuk mencari produk",
          "3. Klik pada produk yang ingin Anda cek stoknya",
          "4. Informasi ketersediaan stok dapat dilihat di halaman detail produk",
          "5. Jika produk tersedia, Anda akan melihat tombol 'Tambah ke Keranjang'"
        ]
      };
    }
    // Cara pembayaran
    else if (message.contains('bayar') || message.contains('pembayaran')) {
      return {
        'type': 'payment_steps',
        'message': 'Berikut cara melakukan pembayaran:',
        'steps': [
          "1. Masukkan produk ke keranjang belanja",
          "2. Klik tombol 'Checkout'",
          "3. Pilih metode pembayaran (Transfer Bank, E-wallet, atau QRIS)",
          "4. Selesaikan pembayaran sesuai instruksi",
          "5. Status pesanan akan diperbarui otomatis setelah pembayaran berhasil"
        ]
      };
    }
    // Cara cek resi
    else if (message.contains('resi') ||
        message.contains('tracking') ||
        message.contains('lacak')) {
      return {
        'type': 'tracking_steps',
        'message': 'Berikut cara melakukan cek resi:',
        'steps': [
          "1. Buka menu 'Pesanan Saya'",
          "2. Pilih pesanan yang ingin dicek status pengirimannya",
          "3. Klik tombol 'Lacak Pengiriman'",
          "4. Anda akan diarahkan ke halaman pelacakan dengan informasi terbaru"
        ]
      };
    }
    // Kontak penjual
    else if (message.contains('kontak') ||
        message.contains('hubungi') ||
        message.contains('penjual') ||
        message.contains('cs')) {
      return {
        'type': 'contact_info',
        'message': 'Berikut informasi kontak penjual:',
        'contacts': [
          {
            "name": "Customer Service UMKM Batik",
            "phone": "+62812-3456-7890",
            "email": "cs@umkmbatik.com",
            "hours": "Senin - Jumat: 08.00 - 17.00 WIB"
          },
          {
            "name": "Whatsapp Support",
            "phone": "+62898-7654-3210",
            "hours": "Setiap hari: 08.00 - 20.00 WIB"
          }
        ]
      };
    }
    // Tentang
    else if (message.contains('tentang') || message.contains('about')) {
      return {
        'type': 'about',
        'message': 'Tentang UMKM Batik',
        'content':
            'UMKM Batik adalah platform digital yang membantu para pengrajin batik lokal untuk memasarkan produk mereka secara online. Kami berkomitmen untuk melestarikan warisan budaya Indonesia sekaligus membantu perekonomian UMKM batik dalam era digital.'
      };
    }
    // Menu bantuan
    else if (message.contains('bantuan') ||
        message.contains('help') ||
        message.contains('menu')) {
      return {
        'type': 'help_menu',
        'message': 'Saya dapat membantu Anda dengan beberapa hal berikut:',
        'menu': [
          "stok - Cara cek stok produk",
          "bayar - Cara melakukan pembayaran",
          "resi - Cara cek resi pengiriman",
          "kontak - Informasi kontak penjual",
          "tentang - Tentang UMKM Batik"
        ]
      };
    }
    // Default menu
    else {
      return {
        'type': 'unknown',
        'message':
            'Maaf, saya belum dapat memahami pertanyaan Anda. Silakan ketik salah satu kata kunci berikut:',
        'menu': [
          "stok - Cara cek stok produk",
          "bayar - Cara melakukan pembayaran",
          "resi - Cara cek resi pengiriman",
          "kontak - Informasi kontak penjual",
          "tentang - Tentang UMKM Batik",
          "menu - Tampilkan menu bantuan"
        ]
      };
    }
  }
}
