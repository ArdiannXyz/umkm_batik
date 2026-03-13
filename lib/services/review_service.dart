import 'dart:convert';
import 'package:http/http.dart' as http;

const String baseUrl = 'http://192.168.70.254:8000/api/v1';

class ReviewService {
     static Future<List<dynamic>> fetchUlasan(String productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews?product_id=$productId'),
        headers: {"Content-Type": "application/json"},
      );

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

  // Cek apakah user sudah pernah review produk ini
static Future<Map<String, dynamic>> checkExistingReview({
  required int productId,
  required int userId,
}) async {
  try {
    // Ambil semua review untuk produk ini dan cek apakah ada dari user
    final response = await http.get(
      Uri.parse('$baseUrl/reviews?product_id=$productId'),
      headers: {"Content-Type": "application/json"},
    );

    print('Response status: ${response.statusCode}'); // Debug
    print('Response body: ${response.body}'); // Debug

    if (response.statusCode == 200) {
      final responseBody = response.body;
      
      // Cek apakah response body kosong
      if (responseBody.isEmpty) {
        return {
          'success': true,
          'data': {
            'has_reviewed': false,
            'review_data': null,
          },
          'message': 'No reviews found for this product',
        };
      }

      final dynamic decodedResponse = jsonDecode(responseBody);
      
      // Pastikan response adalah List
      if (decodedResponse is! List) {
        print('Response is not a List: $decodedResponse');
        return {
          'success': false,
          'data': {
            'has_reviewed': false,
            'review_data': null,
          },
          'message': 'Unexpected response format',
        };
      }

      final List<dynamic> reviews = decodedResponse;
      
      // Cari review dari user ini dengan cara yang aman
      Map<String, dynamic>? existingReview;
      
      try {
        // Gunakan where dan isNotEmpty untuk menghindari error firstWhere
        final userReviews = reviews.where((review) {
          // Pastikan review bukan null dan memiliki user_id
          if (review == null || review is! Map<String, dynamic>) {
            return false;
          }
          
          // Cek user_id dengan berbagai kemungkinan tipe data
          final reviewUserId = review['user_id'];
          if (reviewUserId == null) return false;
          
          // Convert ke int untuk perbandingan
          int? reviewUserIdInt;
          if (reviewUserId is int) {
            reviewUserIdInt = reviewUserId;
          } else if (reviewUserId is String) {
            reviewUserIdInt = int.tryParse(reviewUserId);
          }
          
          return reviewUserIdInt == userId;
        }).toList();
        
        if (userReviews.isNotEmpty) {
          existingReview = Map<String, dynamic>.from(userReviews.first);
        }
      } catch (e) {
        print('Error filtering reviews: $e');
        return {
          'success': false,
          'data': {
            'has_reviewed': false,
            'review_data': null,
          },
          'message': 'Error processing reviews data: ${e.toString()}',
        };
      }

      // Format response sesuai dengan yang diharapkan caller
      if (existingReview != null) {
        return {
          'success': true,
          'data': {
            'has_reviewed': true,
            'review_data': existingReview,
          },
          'message': 'Review found',
        };
      } else {
        return {
          'success': true,
          'data': {
            'has_reviewed': false,
            'review_data': null,
          },
          'message': 'No review found for this user',
        };
      }
    } else {
      return {
        'success': false,
        'data': {
          'has_reviewed': false,
          'review_data': null,
        },
        'message': 'Gagal memeriksa status ulasan: ${response.statusCode}',
      };
    }
  } catch (e) {
    print('Exception in checkExistingReview: $e');
    return {
      'success': false,
      'data': {
        'has_reviewed': false,
        'review_data': null,
      },
      'message': 'Terjadi kesalahan: ${e.toString()}',
    };
  }
}

  // Submit review baru (Anda perlu membuat endpoint CREATE di Laravel)
  static Future<Map<String, dynamic>> submitReview({
    required int productId,
    required int userId,
    required int rating,
    required String komentar,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'product_id': productId,
          'user_id': userId,
          'rating': rating,
          'komentar': komentar,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': true,
          'message': result['message'] ?? 'Review berhasil ditambahkan',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Terjadi kesalahan saat mengirim ulasan',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Update review menggunakan endpoint Laravel
  static Future<Map<String, dynamic>> updateReview({
    required int reviewId, // Tidak digunakan di Laravel API, tapi tetap dijaga untuk kompatibilitas
    required int productId,
    required int userId,
    required int rating,
    required String komentar,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/reviews/manage'),
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
          'success': result['success'] ?? true,
          'message': result['message'] ?? 'Ulasan berhasil diperbarui',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal update: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Alternative update method menggunakan POST dengan header override
  static Future<Map<String, dynamic>> updateReviewWithOverride({
    required int reviewId,
    required int productId,
    required int userId,
    required int rating,
    required String komentar,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/manage'),
        headers: {
          "Content-Type": "application/json",
          "X-HTTP-Method-Override": "PUT"
        },
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
          'success': result['success'] ?? true,
          'message': result['message'] ?? 'Ulasan berhasil diperbarui',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal update: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Delete review menggunakan endpoint Laravel
  static Future<Map<String, dynamic>> deleteReview({
    required int productId,
    required int userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reviews/manage'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          'product_id': productId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return {
          'success': result['success'] ?? true,
          'message': result['message'] ?? 'Ulasan berhasil dihapus',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal hapus: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Alternative delete method menggunakan POST dengan header override
  static Future<Map<String, dynamic>> deleteReviewWithOverride({
    required int productId,
    required int userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/manage'),
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
          'success': result['success'] ?? true,
          'message': result['message'] ?? 'Ulasan berhasil dihapus',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal hapus: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Fetch reviews dengan response wrapper
  static Future<Map<String, dynamic>> fetchReviews(int productId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reviews?product_id=$productId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return {'success': true, 'data': data};
        } else {
          return {'success': false, 'message': 'Data tidak valid'};
        }
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Gagal memuat ulasan: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  // Helper method untuk mendapatkan review spesifik user
  static Future<Map<String, dynamic>> getUserReview({
    required int productId,
    required int userId,
  }) async {
    try {
      final reviewsResult = await fetchReviews(productId);
      
      if (reviewsResult['success']) {
        final List<dynamic> reviews = reviewsResult['data'];
        final userReview = reviews.firstWhere(
          (review) => review['user_id'] == userId,
          orElse: () => null,
        );

        if (userReview != null) {
          return {
            'success': true,
            'data': userReview,
          };
        } else {
          return {
            'success': false,
            'message': 'Review user tidak ditemukan',
          };
        }
      } else {
        return reviewsResult;
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }
}