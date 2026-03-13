// product_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

const String baseUrl = 'http://192.168.70.254:8000/api';

class ProductService {
  static final Map<String, dynamic> _cache = {};
  static final Duration _cacheDuration = Duration(minutes: 15);
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Helper method to safely convert string to double
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double from string: $value - $e');
        return null;
      }
    }
    return null;
  }

  // Helper method to safely convert string to int
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Error parsing int from string: $value - $e');
        return null;
      }
    }
    return null;
  }

  // Helper method to normalize JSON data before parsing
  static Map<String, dynamic> _normalizeProductJson(Map<String, dynamic> json) {
    Map<String, dynamic> normalized = Map<String, dynamic>.from(json);
    
    // List of fields that should be doubles
    List<String> doubleFields = ['price', 'harga', 'original_price', 'discount_price'];
    // List of fields that should be ints
    List<String> intFields = ['id', 'product_id', 'stock', 'stok', 'quantity'];
    
    // Convert double fields
    for (String field in doubleFields) {
      if (normalized.containsKey(field)) {
        normalized[field] = _parseDouble(normalized[field]);
      }
    }
    
    // Convert int fields
    for (String field in intFields) {
      if (normalized.containsKey(field)) {
        normalized[field] = _parseInt(normalized[field]);
      }
    }
    
    return normalized;
  }

  // Get all products
  static Future<List<Product>> GetProducts() async {
    const String cacheKey = 'products_list';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((item) => Product.fromJson(_normalizeProductJson(item)))
          .toList();
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          // Cache the response
          _cacheData(cacheKey, jsonResponse['data']);
          
          return (jsonResponse['data'] as List)
              .map((item) => Product.fromJson(_normalizeProductJson(Map<String, dynamic>.from(item))))
              .toList();
        } else {
          print('API Error: ${jsonResponse['message'] ?? 'Unknown error'}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception while fetching products: $e');
      // Print more details for debugging
      print('Stack trace: ${StackTrace.current}');
    }
    return [];
  }

  // Get product detail by ID
  static Future<Product?> fetchProductDetail(int productId) async {
    final String cacheKey = 'product_detail_$productId';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return Product.fromJson(_normalizeProductJson(_cache[cacheKey]));
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // Cache the response
        _cacheData(cacheKey, jsonResponse);
        
        return Product.fromJson(_normalizeProductJson(Map<String, dynamic>.from(jsonResponse)));
      } else if (response.statusCode == 404) {
        print('Product not found');
      } else {
        print('HTTP error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Exception while fetching product detail: $e');
      print('Stack trace: ${StackTrace.current}');
    }
    return null;
  }

  // Get product images by product ID
  static Future<List<ProductImage>> getProductImages(int productId) async {
    final String cacheKey = 'product_images_$productId';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      return (_cache[cacheKey] as List)
          .map((item) => ProductImage.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/images'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true) {
          // Cache the response
          _cacheData(cacheKey, jsonResponse['data']);
          
          return (jsonResponse['data'] as List)
              .map((item) => ProductImage.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
    } catch (e) {
      print('Exception while fetching product images: $e');
    }
    return [];
  }

  // Get optimized image with width parameter
  static Future<Uint8List?> fetchOptimizedImage(int imageId, {int? width}) async {
    try {
      String url = '$baseUrl/images/$imageId';
      if (width != null && width > 0) {
        url += '?width=$width';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to load image: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while fetching image: $e');
    }
    return null;
  }

  // Get main product image by product ID
  static Future<Uint8List?> fetchMainProductImage(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId/main-image'),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Failed to load main image: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception while fetching main image: $e');
    }
    return null;
  }

  // Convert base64 string to Uint8List
  static Uint8List? base64ToBytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    try {
      // Remove data URL prefix if present
      String cleanBase64 = base64String;
      if (base64String.startsWith('data:image/')) {
        cleanBase64 = base64String.split(',')[1];
      }
      
      // Remove any whitespace or newlines
      cleanBase64 = cleanBase64.replaceAll(RegExp(r'\s'), '');
      
      return base64Decode(cleanBase64);
    } catch (e) {
      print('Error converting base64 to bytes: $e');
      return null;
    }
  }

  // Alternative method for backward compatibility
  static Future<Map<String, dynamic>?> fetchProduct(dynamic productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$productId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['id'] != null) {
          return _normalizeProductJson(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e) {
      print("Error fetching product: $e");
      return null;
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

  // Fungsi untuk mendapatkan URL gambar leng

  // Cache validation
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final timestamp = _cacheTimestamps[key]!;
    final now = DateTime.now();
    return now.difference(timestamp) < _cacheDuration;
  }

  // Store data in cache
  static void _cacheData(String key, dynamic data) {
    _cache[key] = data;
    _cacheTimestamps[key] = DateTime.now();
  }

  // Clear cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Clear specific cache entry
  static void clearCacheKey(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }

  // Refresh products cache
  static Future<void> refreshProductsCache() async {
    clearCacheKey('products_list');
    await GetProducts();
  }

  // Refresh specific product cache
  static Future<void> refreshProductCache(int productId) async {
    clearCacheKey('product_detail_$productId');
    clearCacheKey('product_images_$productId');
    await fetchProductDetail(productId);
  }

static Future<Map<String, dynamic>> sendMessage(String message, {bool useOfflineFallback = true}) async {
  final url = Uri.parse('$baseUrl/chatbot');

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'question': message}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  } catch (e) {
    if (useOfflineFallback) {
      return getOfflineResponse(message);
    } else {
      throw Exception('Gagal menghubungi server dan fallback tidak diaktifkan.');
    }
  }
}




}
