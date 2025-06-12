import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/cartitem.dart';

const String baseUrl = 'http://192.168.70.254:8000/api';

class CartService {
 
 final BuildContext context;
  final int? userId;

  CartService({required this.context, required this.userId});

  Future<void> addToCart(int productId, int quantity) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Silakan login terlebih dahulu")),
      );
      return;
    }

    final url = Uri.parse('$baseUrl/cart/add');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'product_id': productId,
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? "Produk berhasil ditambahkan ke keranjang"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Gagal menambahkan ke keranjang")),
          );
        }
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Gagal menambahkan ke keranjang")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Terjadi kesalahan: $e")),
      );
    }
  }

  static Future<Map<String, dynamic>> fetchCart(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cart?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': data['success'],
          'data': data['data'],
          'message': data['message'],
          'statusCode': response.statusCode,
        };
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Update quantity
  static Future<Map<String, dynamic>> updateQuantity({
    required int cartId,
    required int newQuantity,
    required String userId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cart/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'cart_id': cartId,
          'quantity': newQuantity,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        final data = json.decode(response.body);
        throw Exception(data['message'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

//remove
static Future<Map<String, dynamic>> removeItem({
  required int cartId,
  required String userId,
}) async {
  final response = await http.delete(
    Uri.parse('$baseUrl/cart/remove'),
    
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'cart_id': cartId,
      'user_id': userId,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
}

//delete multiple items
static Future<int> deleteMultipleItems({
  required List<CartItem> items,
  required String userId,
}) async {
  int successCount = 0;

  for (var item in items) {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cart/remove'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cart_id': item.id,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          successCount++;
        }
      }
    } catch (e) {
      print('Error deleting item ${item.id}: $e');
      continue;
    }
  }

  return successCount;
}




  

static Future<Map<String, dynamic>> createOrder({
  required int userId,
  required List<Map<String, dynamic>> items,
  required String alamatPemesanan,
  required String metodePengiriman,
  required String metodePembayaran,
  required int ongkosKirim,
  required String kotaTujuan,
  required String provinsiTujuan,
  required String? kotaTujuanId,
  required String estimasiPengiriman,
  required int beratTotal,
  required bool isStandardShipping,
  required String courierName,
  required String serviceName,
  required String shippingCategory,
  required bool isSameCity,
  required bool isSameProvince,
  required bool isInterIsland,
  required bool isSameIsland,
  required int biayaLayanan,
  required int subtotalItems,
  required int jumlahItems,
  required int totalHarga,
  String? notes, // Add optional notes parameter
}) async {
  // Make sure items have the required structure for each item
  final processedItems = items.map((item) {
    return {
      'product_id': item['product_id'],
      'kuantitas': item['kuantitas'] ?? item['quantity'], // Handle both naming conventions
      'harga': item['harga'] ?? item['price'], // Handle both naming conventions
      'nama_produk': item['nama_produk'] ?? item['product_name'], // Optional but good to include
      'berat': item['berat'] ?? item['weight'], // Optional
      'product_image': item['product_image'], // Optional
    };
  }).toList();

  final orderData = {
    'user_id': userId,
    'total_harga': totalHarga,
    'alamat_pemesanan': alamatPemesanan,
    'metode_pengiriman': metodePengiriman,
    'metode_pembayaran': metodePembayaran,
    'ongkos_kirim': ongkosKirim,
    'kota_tujuan': kotaTujuan,
    'provinsi_tujuan': provinsiTujuan,
    'kota_tujuan_id': kotaTujuanId,
    'estimasi_pengiriman': estimasiPengiriman,
    'berat_total': beratTotal,
    'is_standard_shipping': isStandardShipping,
    'courier_name': courierName,
    'service_name': serviceName,
    'shipping_category': shippingCategory,
    'is_same_city': isSameCity,
    'is_same_province': isSameProvince,
    'is_inter_island': isInterIsland,
    'is_same_island': isSameIsland,
    'biaya_layanan': biayaLayanan,
    'subtotal_items': subtotalItems,
    'jumlah_items': jumlahItems,
    'notes': notes ?? '', // Add notes field (required by Laravel, nullable)
    'items': processedItems, // Use processed items
  };

  try {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/create-transaction'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json', // Ensure we expect JSON response
      },
      body: jsonEncode(orderData),
    );

    print('Request URL: $baseUrl/cart/create-transaction');
    print('Request body: ${jsonEncode(orderData)}');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    // Handle empty response
    if (response.body.isEmpty) {
      return {
        'statusCode': response.statusCode,
        'data': {'success': false, 'message': 'Empty response from server'},
      };
    }

    // Handle HTML response (usually error pages)
    if (response.body.trim().toLowerCase().startsWith('<!doctype') || 
        response.body.trim().toLowerCase().startsWith('<html')) {
      return {
        'statusCode': response.statusCode,
        'data': {'success': false, 'message': 'Server returned HTML instead of JSON'},
      };
    }

    // Try to decode JSON
    try {
      final responseData = jsonDecode(response.body);
      return {
        'statusCode': response.statusCode,
        'data': responseData,
      };
    } catch (jsonError) {
      print('JSON decode error: $jsonError');
      return {
        'statusCode': response.statusCode,
        'data': {
          'success': false, 
          'message': 'Invalid JSON response',
          'raw_response': response.body,
          'error': jsonError.toString(),
        },
      };
    }
  } catch (e) {
    print('HTTP request error: $e');
    return {
      'statusCode': 0,
      'data': {
        'success': false,
        'message': 'Network error occurred',
        'error': e.toString(),
      },
    };
  }
}

static Future<String> getBase64Image(int imageId) async {
    final url = Uri.parse('$baseUrl/image/$imageId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['image_base64'];
    } else {
      throw Exception('Failed to load image');
    }
  }

}
