import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:umkm_batik/pages/payment_method.dart';
import 'package:http/http.dart' as http;
import '../models/Address.dart';
import '../models/ShippinCost.dart';



const String baseUrl = 'http://192.168.70.254:8000/api/api';

class PaymentService { 

  // Helper method untuk mengecek response success
  static bool _isSuccessResponse(Map<String, dynamic> responseBody) {
    // Support both formats untuk backward compatibility
    return (responseBody['success'] == true) || 
           (responseBody['status'] == 'success');
  }

  // Helper method untuk mendapatkan error message
  static String _getErrorMessage(Map<String, dynamic> responseBody) {
    return responseBody['message'] ?? 'Unknown error occurred';
  }

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
        'user_id': int.parse(userId),
        'total_harga': totalPayment,
        'alamat_pemesanan':
            '${selectedAddress.alamatLengkap}, ${selectedAddress.kecamatan}, ${selectedAddress.kota}, ${selectedAddress.provinsi}, ${selectedAddress.kodePos}',
        'metode_pengiriman': selectedShippingOption?.displayName ?? 'Standar',
        'metode_pembayaran': selectedPaymentMethod.name.toLowerCase(),
        'notes': 'Shipping: $shippingCategory, Courier: ${selectedShippingOption?.courier ?? 'STANDAR'}, Service: ${selectedShippingOption?.service ?? 'REGULER'}, ETD: ${selectedShippingOption?.etd ?? '3-7'} hari, Biaya layanan: $serviceFee',
        'items': [
          {
            'product_id': product.id,
            'kuantitas': product.quantity,
            'harga': product.price,
          }
        ],
      };

      final response = await http.post(
        Uri.parse('$baseUrl/create-transaction'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(orderData),
      );

      final responseBody = jsonDecode(response.body);

      return {
        'statusCode': response.statusCode,
        'body': responseBody,
        'success': _isSuccessResponse(responseBody), // Tambahkan flag success
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'error': e.toString(),
        'success': false,
      };
    }
  }

  static Future<Map<String, dynamic>> cancelOrder({
    required String orderId,
    required String reason,
  }) async {
    try {
      int orderIdInt;
      try {
        orderIdInt = int.parse(orderId);
      } catch (e) {
        throw FormatException('Format order ID tidak valid: $orderId');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderIdInt/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'reason': reason,
        }),
      );

      final responseBody = jsonDecode(response.body);

      return {
        'statusCode': response.statusCode,
        'body': responseBody,
        'success': _isSuccessResponse(responseBody),
        'message': _getErrorMessage(responseBody),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'error': e.toString(),
        'success': false,
      };
    }
  }

  static Future<List<Map<String, dynamic>>> fetchOrders({
    required String userId,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'user_id': userId,
      };
      
      if (status != null && status.isNotEmpty) {
        String mappedStatus = _mapStatusToBackend(status);
        if (mappedStatus.isNotEmpty) {
          queryParams['status'] = mappedStatus;
        }
      }

      print('Query params: $queryParams');
      
      final uri = Uri.parse('$baseUrl/orders').replace(queryParameters: queryParams);
      print('Full URL: $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Support both response formats
        if (_isSuccessResponse(data) && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          print('API returned error or null data: ${data['message'] ?? 'Unknown error'}');
          return [];
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception in fetchOrders: $e');
      throw Exception('Failed to fetch orders: $e');
    }
  }

  static Future<Map<String, dynamic>?> fetchOrderDetail({
    required String orderId,
    required String userId,
  }) async {
    try {
      int orderIdInt;
      try {
        orderIdInt = int.parse(orderId);
      } catch (e) {
        throw FormatException('Format order ID tidak valid: $orderId');
      }

      final uri = Uri.parse('$baseUrl/orders/$orderIdInt').replace(
        queryParameters: {'user_id': userId},
      );
      
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (_isSuccessResponse(data)) {
          return data['data'];
        }
      } else {
        print('Error fetching order detail: ${response.statusCode}');
        final errorData = jsonDecode(response.body);
        print('Error message: ${errorData['message'] ?? 'Unknown error'}');
      }

      return null;
    } catch (e) {
      print('Error fetching order detail: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> confirmOrderCompleted({
    required String orderId,
    required String userId,
  }) async {
    try {
      int orderIdInt;
      try {
        orderIdInt = int.parse(orderId);
      } catch (e) {
        throw FormatException('Format order ID tidak valid: $orderId');
      }

      final requestBody = {
        'user_id': int.parse(userId),
      };

      final response = await http.put(
        Uri.parse('$baseUrl/orders/$orderIdInt/complete'),
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
        'success': _isSuccessResponse(data),
        'message': _getErrorMessage(data),
      };
    } catch (e) {
      return {
        'statusCode': 500,
        'error': e.toString(),
        'success': false,
      };
    }
  }

  // Helper methods tetap sama
  static String _mapStatusToBackend(String flutterStatus) {
    switch (flutterStatus.toLowerCase()) {
      case 'pending':
      case 'belum bayar':
      case 'belum_bayar':
        return 'pending';
      case 'paid':
      case 'dibayar':
      case 'sudah_bayar':
        return 'paid';
      case 'shipped':
      case 'dikirim':
      case 'dalam_pengiriman':
        return 'shipped';
      case 'completed':
      case 'selesai':
      case 'complete':
        return 'completed';
      case 'cancelled':
      case 'canceled':
      case 'batal':
        return 'cancelled';
      default:
        print('Unknown status: $flutterStatus');
        return '';
    }
  }

  
}
