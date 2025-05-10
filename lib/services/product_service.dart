// product_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/product_image.dart';

const String baseUrl = 'http://192.168.231.254/umkm_batik/API/';

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
      return jsonResponse
          .map((item) => ProductImage.fromJson(item))
          .toList();
    } else {
      print('HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    print('Exception saat ambil gambar produk: $e');
  }
  return [];
}


}
