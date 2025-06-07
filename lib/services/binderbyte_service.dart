// services/binderbyte_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/binderbyte_models.dart';

class BinderByteService {
  static const String _baseUrl = 'https://api.binderbyte.com';
  static const String _apiKey = '6ff83830ff482eb07dcab53ce37b0f2918e2574aa599c75b0d9aee857472a767'; // Ganti dengan API key Anda
  
  // Untuk testing, bisa menggunakan trial dengan batasan
  static const String _wilayahApiKey = _apiKey;
  static const String _cekResiApiKey = _apiKey;

  // Headers standar untuk semua request
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // ========== API WILAYAH ==========

  /// Mendapatkan daftar provinsi
  static Future<BinderByteApiResponse<List<BinderByteProvince>>> getProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wilayah/provinsi?api_key=$_wilayahApiKey'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          final provinces = (jsonData['data'] as List)
              .map((item) => BinderByteProvince.fromJson(item))
              .toList();
          
          return BinderByteApiResponse<List<BinderByteProvince>>(
            success: true,
            message: jsonData['message'] ?? 'Success',
            data: provinces,
            code: jsonData['code'],
          );
        } else {
          return BinderByteApiResponse<List<BinderByteProvince>>(
            success: false,
            message: jsonData['message'] ?? 'Failed to fetch provinces',
            code: jsonData['code'],
          );
        }
      } else {
        return BinderByteApiResponse<List<BinderByteProvince>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BinderByteApiResponse<List<BinderByteProvince>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Mendapatkan daftar kota/kabupaten berdasarkan ID provinsi
  static Future<BinderByteApiResponse<List<BinderByteCity>>> getCities(String provinceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wilayah/kabupaten?api_key=$_wilayahApiKey&id_provinsi=$provinceId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          final cities = (jsonData['data'] as List)
              .map((item) => BinderByteCity.fromJson(item))
              .toList();
          
          return BinderByteApiResponse<List<BinderByteCity>>(
            success: true,
            message: jsonData['message'] ?? 'Success',
            data: cities,
            code: jsonData['code'],
          );
        } else {
          return BinderByteApiResponse<List<BinderByteCity>>(
            success: false,
            message: jsonData['message'] ?? 'Failed to fetch cities',
            code: jsonData['code'],
          );
        }
      } else {
        return BinderByteApiResponse<List<BinderByteCity>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BinderByteApiResponse<List<BinderByteCity>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Mendapatkan daftar kecamatan berdasarkan ID kota/kabupaten
  static Future<BinderByteApiResponse<List<BinderByteDistrict>>> getDistricts(String cityId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wilayah/kecamatan?api_key=$_wilayahApiKey&id_kabupaten=$cityId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          final districts = (jsonData['data'] as List)
              .map((item) => BinderByteDistrict.fromJson(item))
              .toList();
          
          return BinderByteApiResponse<List<BinderByteDistrict>>(
            success: true,
            message: jsonData['message'] ?? 'Success',
            data: districts,
            code: jsonData['code'],
          );
        } else {
          return BinderByteApiResponse<List<BinderByteDistrict>>(
            success: false,
            message: jsonData['message'] ?? 'Failed to fetch districts',
            code: jsonData['code'],
          );
        }
      } else {
        return BinderByteApiResponse<List<BinderByteDistrict>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BinderByteApiResponse<List<BinderByteDistrict>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  /// Mendapatkan daftar kelurahan berdasarkan ID kecamatan
  static Future<BinderByteApiResponse<List<BinderByteVillage>>> getVillages(String districtId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/wilayah/kelurahan?api_key=$_wilayahApiKey&id_kecamatan=$districtId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          final villages = (jsonData['data'] as List)
              .map((item) => BinderByteVillage.fromJson(item))
              .toList();
          
          return BinderByteApiResponse<List<BinderByteVillage>>(
            success: true,
            message: jsonData['message'] ?? 'Success',
            data: villages,
            code: jsonData['code'],
          );
        } else {
          return BinderByteApiResponse<List<BinderByteVillage>>(
            success: false,
            message: jsonData['message'] ?? 'Failed to fetch villages',
            code: jsonData['code'],
          );
        }
      } else {
        return BinderByteApiResponse<List<BinderByteVillage>>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BinderByteApiResponse<List<BinderByteVillage>>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ========== API CEK RESI ==========

  /// Melacak resi berdasarkan kurir dan nomor resi
  static Future<BinderByteApiResponse<BinderByteTrackingResult>> trackPackage({
    required String courier,
    required String waybill,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cekresi?api_key=$_cekResiApiKey&courier=$courier&waybill=$waybill'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          final trackingResult = BinderByteTrackingResult.fromJson(jsonData['data']);
          
          return BinderByteApiResponse<BinderByteTrackingResult>(
            success: true,
            message: jsonData['message'] ?? 'Success',
            data: trackingResult,
            code: jsonData['code'],
          );
        } else {
          return BinderByteApiResponse<BinderByteTrackingResult>(
            success: false,
            message: jsonData['message'] ?? 'Failed to track package',
            code: jsonData['code'],
          );
        }
      } else {
        return BinderByteApiResponse<BinderByteTrackingResult>(
          success: false,
          message: 'HTTP Error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return BinderByteApiResponse<BinderByteTrackingResult>(
        success: false,
        message: 'Network error: $e',
      );
    }
  }

  // ========== UTILITY METHODS ==========

  /// Mencari kota berdasarkan nama (untuk integrasi dengan sistem yang ada)
  static Future<Map<String, dynamic>> findCityByName({
    required String cityName,
    required String provinceName,
  }) async {
    try {
      // Pertama, dapatkan daftar provinsi
      final provincesResponse = await getProvinces();
      if (!provincesResponse.success || provincesResponse.data == null) {
        return {
          'success': false,
          'message': 'Failed to fetch provinces: ${provincesResponse.message}',
        };
      }

      // Cari provinsi yang sesuai
      final targetProvince = provincesResponse.data!.firstWhere(
        (province) => province.name.toLowerCase().contains(provinceName.toLowerCase()),
        orElse: () => throw Exception('Province not found'),
      );

      // Dapatkan daftar kota dalam provinsi tersebut
      final citiesResponse = await getCities(targetProvince.id);
      if (!citiesResponse.success || citiesResponse.data == null) {
        return {
          'success': false,
          'message': 'Failed to fetch cities: ${citiesResponse.message}',
        };
      }

      // Cari kota yang sesuai
      final targetCity = citiesResponse.data!.firstWhere(
        (city) => city.name.toLowerCase().contains(cityName.toLowerCase()),
        orElse: () => throw Exception('City not found'),
      );

      return {
        'success': true,
        'message': 'City found successfully',
        'selectedCity': {
          'cityId': targetCity.id,
          'cityName': targetCity.name,
          'province': targetProvince.name,
          'provinceId': targetProvince.id,
        },
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error finding city: $e',
      };
    }
  }

  /// Mendapatkan ongkos kirim (simulasi - karena BinderByte tidak memiliki API ongkir)
  /// Ini bisa digabungkan dengan RajaOngkir atau sistem lain
  static Future<Map<String, dynamic>> getShippingCostsByAddress({
    required String cityName,
    required String provinceName,
    required int weight,
    List<String>? preferredCouriers,
  }) async {
    try {
      // Cari kota menggunakan API wilayah BinderByte
      final cityResult = await findCityByName(
        cityName: cityName,
        provinceName: provinceName,
      );

      if (!cityResult['success']) {
        return cityResult;
      }

      // Karena BinderByte tidak memiliki API ongkir, kita return informasi kota
      // yang bisa digunakan untuk integrasi dengan service ongkir lain
      return {
        'success': true,
        'message': 'City information retrieved successfully',
        'selectedCity': cityResult['selectedCity'],
        'shippingOptions': <BinderByteShippingCost>[], // Kosong karena tidak ada API ongkir
        'note': 'BinderByte does not provide shipping cost calculation. Use RajaOngkir or other services.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting shipping costs: $e',
      };
    }
  }

  // ========== API KEY VALIDATION ==========

  /// Memvalidasi API key
  static Future<bool> validateApiKey() async {
    try {
      final response = await getProvinces();
      return response.success;
    } catch (e) {
      return false;
    }
  }

  // ========== SUPPORTED COURIERS FOR TRACKING ==========

  /// Daftar kurir yang didukung untuk tracking
  static List<String> get supportedCouriers => [
        'jne',
        'pos',
        'jnt',
        'wahana',
        'tiki',
        'sicepat',
        'anteraja',
        'lion',
        'ninja',
        'pcp',
        'jet',
      ];

  /// Mengecek apakah kurir didukung untuk tracking
  static bool isCourierSupported(String courier) {
    return supportedCouriers.contains(courier.toLowerCase());
  }
}