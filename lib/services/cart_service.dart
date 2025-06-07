import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cartitem.dart';

const String baseUrl = 'http://192.168.180.254/umkm_batik/API/';

class CartService {
 

  static Future<Map<String, dynamic>> fetchCart(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_cart.php?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
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
      throw Exception('Server error: ${response.statusCode}');
    }
  }
  //update
  static Future<Map<String, dynamic>> updateQuantity({
  required int cartId,
  required int newQuantity,
  required String userId,
}) async {
  final response = await http.put(
    Uri.parse('$baseUrl/update_cart.php'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'cart_id': cartId,
      'quantity': newQuantity,
      'user_id': userId,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
}

//remove
static Future<Map<String, dynamic>> removeItem({
  required int cartId,
  required String userId,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/delete_cart.php'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'cart_id': cartId,
      'quantity': 0,
      'user_id': userId,
    }),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Server error: ${response.statusCode}');
  }
}
//delete
static Future<int> deleteMultipleItems({
  required List<CartItem> items,
  required String userId,
}) async {
  int successCount = 0;

  for (var item in items) {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/delete_cart.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'cart_id': item.id,
          'quantity': 0,
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


}
