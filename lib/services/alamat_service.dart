// alamat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Address.dart';

const String baseUrl = 'http://192.168.70.254:8000/api';

class AlamatService {

  static Future<Map<String, dynamic>> submitAlamat(Map<String, dynamic> data) async {
    try {
      // Pastikan user_id dalam format integer
      final Map<String, dynamic> requestData = Map.from(data);
      if (requestData['user_id'] is String) {
        requestData['user_id'] = int.parse(requestData['user_id']);
      }

      print('Submit alamat request data: $requestData');

      final url = Uri.parse('$baseUrl/addresses/create');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestData),
      );

      print('Submit alamat response status: ${response.statusCode}');
      print('Submit alamat response body: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('Error in submitAlamat: $e');
      throw Exception('Gagal mengirim data alamat: $e');
    }
  }

  static Future<List<Address>> fetchAddresses(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/addresses?user_id=$userId'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['success'] == true) {
        return (responseData['data'] as List)
            .map((item) => Address.fromJson(item))
            .toList();
      } else {
        throw Exception(responseData['message'] ?? 'Gagal memuat alamat');
      }
    } else {
      throw Exception('Terjadi kesalahan. Kode: ${response.statusCode}');
    }
  }

  static Future<void> deleteAddress(String userId, String addressId) async {
    final Map<String, dynamic> data = {
      'id': int.parse(addressId),
      'user_id': int.parse(userId),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/addresses/delete'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);

      if (responseData['success'] != true) {
        throw Exception(responseData['message'] ?? 'Gagal menghapus alamat');
      }
    } else {
      throw Exception('Terjadi kesalahan. Kode: ${response.statusCode}');
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.reasonPhrase}');
    }
  }

  Future<Map<String, dynamic>> fetchAddressDetails(String userId, String addressId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/addresses?user_id=$userId'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        final addresses = (responseData['data'] as List);
        print('addresses: $addresses');
        print('addressId to find: $addressId');

        try {
          final addressData = addresses.firstWhere(
            (address) {
              print('checking address id: ${address['id']}');
              return address['id'].toString() == addressId.toString();
            },
          );


          return {
            'success': true,
            'data': addressData,
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Alamat tidak ditemukan',
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Gagal memuat alamat',
        };
      }
    } else {
      return {
        'success': false,
        'message': 'Terjadi kesalahan. Kode: ${response.statusCode}',
      };
    }
  }

  Future<Map<String, dynamic>> updateAddress(Map<String, dynamic> data) async {
    try {
      // Pastikan semua field yang diperlukan ada dan dalam tipe data yang benar
      final Map<String, dynamic> requestData = {
        'id': data['id'] is String ? int.parse(data['id']) : data['id'],
        'user_id': data['user_id'] is String ? int.parse(data['user_id']) : data['user_id'],
        'nama_lengkap': data['nama_lengkap']?.toString() ?? '',
        'nomor_hp': data['nomor_hp']?.toString() ?? '',
        'provinsi': data['provinsi']?.toString() ?? '',
        'kota': data['kota']?.toString() ?? '',
        'kecamatan': data['kecamatan']?.toString() ?? '',
        'kode_pos': data['kode_pos']?.toString() ?? '',
        'alamat_lengkap': data['alamat_lengkap']?.toString() ?? '',
      };

      print('Update request data: $requestData');

      final response = await http.post(
        Uri.parse('$baseUrl/addresses/update'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestData),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': responseData['success'] == true,
          'message': responseData['message'] ?? '',
        };
      } else if (response.statusCode == 400) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Data tidak valid',
        };
      } else if (response.statusCode == 403) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Tidak memiliki izin untuk mengubah alamat ini',
        };
      } else {
        return {
          'success': false,
          'message': 'Terjadi kesalahan server. Kode: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error in updateAddress: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
}
