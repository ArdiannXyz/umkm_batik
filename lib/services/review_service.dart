import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://192.168.180.254/umkm_batik/API/';

class ReviewService {
    static Future<List<dynamic>> fetchUlasan(String productId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/get_reviews.php?product_id=$productId'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return data;
        }
      }
    } catch (e) {
      print('Error fetching reviews: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> checkExistingReview({
    required int productId,
    required int userId,
  }) async {
    final url = Uri.parse("$baseUrl/check_reviews.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'product_id': productId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'data': result,
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal memeriksa status ulasan: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> submitReview({
    required int productId,
    required int userId,
    required int rating,
    required String komentar,
  }) async {
    final url = Uri.parse("$baseUrl/add_reviews.php");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'product_id': productId,
          'user_id': userId,
          'rating': rating,
          'komentar': komentar,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['success'] == true,
          'message': result['message'] ?? 'Gagal mengirim ulasan',
        };
      } else {
        return {
          'success': false,
          'message': 'Terjadi kesalahan saat mengirim ulasan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

     static Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int productId,
    required int userId,
    required int rating,
    required String komentar,
  }) async {
    final url = Uri.parse("$baseUrl/edit_reviews.php");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-HTTP-Method-Override": "PUT"
        },
        body: jsonEncode({
          'review_id': reviewId,
          'product_id': productId,
          'user_id': userId,
          'rating': rating,
          'komentar': komentar,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': result['message'] ?? 'Ulasan berhasil diperbarui',
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal update: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> deleteReview({
    required int productId,
    required int userId,
  }) async {
    final url = Uri.parse("$baseUrl/delete_reviews.php");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-HTTP-Method-Override": "DELETE"
        },
        body: jsonEncode({
          'product_id': productId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': result['message'] ?? 'Ulasan berhasil dihapus',
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal hapus: ${response.statusCode} - ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> fetchReviews(int productId) async {
  final url = Uri.parse("$baseUrl/get_reviews.php?product_id=$productId");

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Data tidak valid'};
      }
    } else {
      return {
        'success': false,
        'message': 'Gagal memuat ulasan: ${response.statusCode}'
      };
    }
  } catch (e) {
    return {'success': false, 'message': 'Error: ${e.toString()}'};
  }
}


}
