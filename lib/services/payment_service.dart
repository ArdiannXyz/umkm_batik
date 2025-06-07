import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/payment_method.dart';
import 'package:http/http.dart' as http;
import '../models/Address.dart';
import '../models/ShippinCost.dart';



const String baseUrl = 'http://192.168.180.254/umkm_batik/API/';


class PaymentService {
  static Future<Map<String, dynamic>> createOrder({
    required BuildContext context,
    required String userId,
    required int totalPayment,
    required Address selectedAddress,
    required PaymentMethod selectedPaymentMethod,
    required ShippingCost? selectedShippingOption, 
    required int shippingCost,
    required dynamic destinationCity,
    required int serviceFee,
    required product,
    required bool Function(String, String) isWithinSameCity,
    required bool Function(String) isWithinSameProvince,
    required bool Function(String) isInterIslandDelivery,
    required bool Function(String) isWithinSameIsland,
  }) async {
    try {
      String shippingCategory;
      if (isWithinSameCity(selectedAddress.kota, selectedAddress.provinsi)) {
        shippingCategory = 'lokal';
      } else if (isWithinSameProvince(selectedAddress.provinsi)) {
        shippingCategory = 'provinsi';
      } else if (isInterIslandDelivery(selectedAddress.provinsi)) {
        shippingCategory = 'luar pulau';
      } else {
        shippingCategory = 'antar provinsi';
      }

      final orderData = {
        'user_id': userId,
        'total_harga': totalPayment,
        'alamat_pemesanan':
            '${selectedAddress.alamatLengkap}, ${selectedAddress.kecamatan}, ${selectedAddress.kota}, ${selectedAddress.provinsi}, ${selectedAddress.kodePos}',
        'metode_pengiriman': selectedShippingOption?.displayName ?? 'Standar',
        'metode_pembayaran': selectedPaymentMethod.name.toLowerCase(),
        'ongkos_kirim': shippingCost,
        'kota_tujuan': selectedAddress.kota,
        'provinsi_tujuan': selectedAddress.provinsi,
        'kota_tujuan_id': destinationCity?.cityId,
        'estimasi_pengiriman': selectedShippingOption?.etd ?? '3-7',
        'berat_total': product.weight * product.quantity,
        'is_standard_shipping': selectedShippingOption?.isStandardOption ?? true,
        'courier_name': selectedShippingOption?.courier ?? 'STANDAR',
        'service_name': selectedShippingOption?.service ?? 'REGULER',
        'shipping_category': shippingCategory,
        'is_same_city': isWithinSameCity(selectedAddress.kota, selectedAddress.provinsi),
        'is_same_province': isWithinSameProvince(selectedAddress.provinsi),
        'is_inter_island': isInterIslandDelivery(selectedAddress.provinsi),
        'is_same_island': isWithinSameIsland(selectedAddress.provinsi),
        'biaya_layanan': serviceFee,
        'items': [
          {
            'product_id': product.id,
            'kuantitas': product.quantity,
            'harga': product.price,
          }
        ],
      };

          final response = await http.post(
      Uri.parse('${baseUrl}create_transaction.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(orderData),
    );


      return {
        'statusCode': response.statusCode,
        'body': jsonDecode(response.body),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'error': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    final url = Uri.parse('$baseUrl/cancel_order.php');

    // Validasi format orderId jika perlu (opsional)
    if (!orderId.contains('-')) {
      try {
        int.parse(orderId);
      } catch (e) {
        throw FormatException('Format order ID tidak valid: $orderId');
      }
    }

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'order_id': orderId,
        'reason': reason,
      }),
    );

    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Format respons tidak valid: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchOrders({
    required String userId,
    required String status,
  }) async {
    final url = '$baseUrl/orders.php?user_id=$userId&status=$status';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success' && data['data'] != null) {
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

  static String getFullImageUrl(String? relativeUrl) {
    if (relativeUrl == null || relativeUrl.isEmpty) return '';

    if (relativeUrl.startsWith('http')) return relativeUrl;

    if (relativeUrl.contains('get_main_product_images.php')) {
      final uri = Uri.tryParse(relativeUrl);
      if (uri != null && uri.queryParameters.containsKey('id')) {
        final productId = uri.queryParameters['id'];
        return '$baseUrl/get_main_product_images.php?id=$productId';
      }
      return '$baseUrl/$relativeUrl';
    }

    final cleanPath =
        relativeUrl.startsWith('/') ? relativeUrl.substring(1) : relativeUrl;
    return '$baseUrl/$cleanPath';
  }

  static Future<Map<String, dynamic>?> fetchOrderDetail({
  required String orderId,
  required String userId,
}) async {
  final url = '$baseUrl/orders.php?order_id=$orderId&user_id=$userId';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'success') {
      return data['data'];
    }
  }

  return null;
}

    static Future<Map<String, dynamic>> confirmOrderCompleted({
  required String orderId,
  required String userId,
}) async {
  final requestBody = {
    'order_id': int.parse(orderId),
    'status': 'completed',
    'user_id': int.parse(userId),
  };

  final response = await http.post(
    Uri.parse('$baseUrl/orders.php'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode(requestBody),
  );

  final data = jsonDecode(response.body);
  return {
    'statusCode': response.statusCode,
    'data': data,
  };
}

  
}
