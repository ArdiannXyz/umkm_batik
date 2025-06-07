// alamat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/Address.dart';

const String baseUrl = 'http://192.168.180.254/umkm_batik/API/';

class AlamatService {
 

  static Future<Map<String, dynamic>> submitAlamat(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/add_addresses.php');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  static Future<List<Address>> fetchAddresses(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_addresses.php?user_id=$userId'),
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
      'id': addressId,
      'user_id': userId,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/delete_addresses.php'),
      headers: {'Content-Type': 'application/json'},
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
      Uri.parse('${baseUrl}get_addresses.php?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['success'] == true) {
        final addresses = (responseData['data'] as List);
        print('addresses: $addresses');
        print('addressId to find: $addressId');

        final addressData = addresses.firstWhere(
          (address) {
            print('checking address id: ${address['id']}');
            return address['id'].toString() == addressId.toString();
          },
          orElse: () => null,
        );

        if (addressData != null) {
          return {
            'success': true,
            'data': addressData,
          };
        } else {
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
    final response = await http.post(
      Uri.parse('${baseUrl}edit_addresses.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return {
        'success': responseData['success'] == true,
        'message': responseData['message'] ?? '',
      };
    } else {
      return {
        'success': false,
        'message': 'Terjadi kesalahan. Kode: ${response.statusCode}',
      };
    }
  }

}
