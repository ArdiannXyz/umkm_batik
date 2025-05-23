import 'dart:convert';
import 'package:http/http.dart' as http;

class RajaOngkirCity {
  final String cityId;
  final String provinceName;
  final String cityName;
  final String type;
  final String postalCode;

  RajaOngkirCity({
    required this.cityId,
    required this.provinceName,
    required this.cityName,
    required this.type,
    required this.postalCode,
  });

  factory RajaOngkirCity.fromJson(Map<String, dynamic> json) {
    return RajaOngkirCity(
      cityId: json['city_id'].toString(),
      provinceName: json['province'],
      cityName: json['city_name'],
      type: json['type'],
      postalCode: json['postal_code'],
    );
  }

  @override
  String toString() {
    return '$cityName ($type), $provinceName';
  }
}

class ShippingCost {
  final String service;
  final String description;
  final int cost;
  final String etd;
  final String courier;
  final bool isStandardOption; // Menandai apakah ini opsi standar

  ShippingCost({
    required this.service,
    required this.description,
    required this.cost,
    required this.etd,
    required this.courier,
    this.isStandardOption = false,
  });

  factory ShippingCost.fromJson(Map<String, dynamic> json, String courierName) {
    return ShippingCost(
      service: json['service'],
      description: json['description'],
      cost: json['cost'][0]['value'],
      etd: json['cost'][0]['etd'],
      courier: courierName.toUpperCase(),
      isStandardOption: false,
    );
  }

  // Factory untuk membuat opsi pengiriman standar
  factory ShippingCost.standardOption({
    required String service,
    required String description,
    required int cost,
    required String etd,
  }) {
    return ShippingCost(
      service: service,
      description: description,
      cost: cost,
      etd: etd,
      courier: 'STANDAR',
      isStandardOption: true,
    );
  }

  String get displayName => '$courier - $service';
  String get fullDescription => '$description ($etd hari)';
}

// Enum untuk menentukan jenis pengiriman berdasarkan lokasi
enum ShippingZone {
  sameProvince, // Satu provinsi (Jawa Timur)
  differentProvince, // Luar provinsi (masih satu pulau)
  differentIsland, // Luar pulau
}

class StandardShippingOption {
  final ShippingZone zone;
  final String service;
  final String description;
  final int baseCost;
  final String etd;
  final double weightMultiplier; // Pengali berdasarkan berat

  StandardShippingOption({
    required this.zone,
    required this.service,
    required this.description,
    required this.baseCost,
    required this.etd,
    this.weightMultiplier = 1.0,
  });
}

class RajaOngkirService {
  // IMPORTANT: Ganti dengan API Key RajaOngkir Anda
  // Dapatkan di: https://rajaongkir.com/akun/api
  static const String _apiKey = 'YOUR_RAJA_ONGKIR_API_KEY_HERE';
  static const String _baseUrl = 'https://api.rajaongkir.com/starter';

  // ID Kota Bondowoso - Jawa Timur
  // Untuk mendapatkan ID yang tepat, gunakan API city dengan parameter province=11 (Jawa Timur)
  static const String _originCityId =
      '35'; // Sesuaikan dengan ID Bondowoso yang benar dari API
  static const String _originProvince = 'JAWA TIMUR';

  // Definisi opsi pengiriman standar
  static final List<StandardShippingOption> _standardShippingOptions = [
    // Pengiriman dalam satu provinsi (Jawa Timur)
    StandardShippingOption(
      zone: ShippingZone.sameProvince,
      service: 'REGULER',
      description: 'Pengiriman reguler dalam provinsi',
      baseCost: 12000,
      etd: '2-4',
      weightMultiplier: 1.0,
    ),

    // Pengiriman luar provinsi (masih satu pulau)
    StandardShippingOption(
      zone: ShippingZone.differentProvince,
      service: 'ANTARPROVINSI',
      description: 'Pengiriman antar provinsi',
      baseCost: 18000,
      etd: '3-6',
      weightMultiplier: 1.2,
    ),

    // Pengiriman luar pulau
    StandardShippingOption(
      zone: ShippingZone.differentIsland,
      service: 'ANTARPULAU',
      description: 'Pengiriman antar pulau',
      baseCost: 25000,
      etd: '5-9',
      weightMultiplier: 1.5,
    ),
  ];

  // Daftar provinsi di Pulau Jawa untuk menentukan zona pengiriman
  static final List<String> _javaProvinces = [
    'DKI JAKARTA',
    'JAWA BARAT',
    'JAWA TENGAH',
    'JAWA TIMUR',
    'DI YOGYAKARTA',
    'BANTEN',
  ];

  /// Menentukan zona pengiriman berdasarkan provinsi tujuan
  static ShippingZone _determineShippingZone(String destinationProvince) {
    final destProvince = destinationProvince.toUpperCase();

    // Jika sama dengan provinsi asal
    if (destProvince == _originProvince) {
      return ShippingZone.sameProvince;
    }

    // Jika masih di Pulau Jawa
    if (_javaProvinces.contains(destProvince)) {
      return ShippingZone.differentProvince;
    }

    // Jika di luar Pulau Jawa
    return ShippingZone.differentIsland;
  }

  /// Menghitung biaya pengiriman standar berdasarkan berat dan zona
  static int _calculateStandardCost(
      StandardShippingOption option, int weightInGrams) {
    // Biaya dasar
    int baseCost = option.baseCost;

    // Tambahan biaya berdasarkan berat (per kg)
    int weightInKg = (weightInGrams / 1000).ceil();
    if (weightInKg > 1) {
      int additionalWeight = weightInKg - 1;
      int additionalCost =
          (additionalWeight * option.baseCost * 0.5 * option.weightMultiplier)
              .round();
      baseCost += additionalCost;
    }

    return baseCost;
  }

  /// Mendapatkan opsi pengiriman standar berdasarkan provinsi tujuan dan berat
  static List<ShippingCost> getStandardShippingOptions({
    required String destinationProvince,
    required int weight,
  }) {
    final zone = _determineShippingZone(destinationProvince);
    final List<ShippingCost> standardOptions = [];

    // Tambahkan opsi sesuai zona
    switch (zone) {
      case ShippingZone.sameProvince:
        // Hanya opsi dalam provinsi
        final option = _standardShippingOptions[0];
        standardOptions.add(ShippingCost.standardOption(
          service: option.service,
          description: option.description,
          cost: _calculateStandardCost(option, weight),
          etd: option.etd,
        ));
        break;

      case ShippingZone.differentProvince:
        // Opsi dalam provinsi (lebih mahal karena jauh) + opsi antar provinsi
        final sameProvinceOption = _standardShippingOptions[0];
        final diffProvinceOption = _standardShippingOptions[1];

        standardOptions.add(ShippingCost.standardOption(
          service: diffProvinceOption.service,
          description: diffProvinceOption.description,
          cost: _calculateStandardCost(diffProvinceOption, weight),
          etd: diffProvinceOption.etd,
        ));

        // Tambahkan opsi ekspres (lebih cepat tapi lebih mahal)
        standardOptions.add(ShippingCost.standardOption(
          service: 'EKSPRES',
          description: 'Pengiriman ekspres antar provinsi',
          cost: (_calculateStandardCost(diffProvinceOption, weight) * 1.4)
              .round(),
          etd: '2-4',
        ));
        break;

      case ShippingZone.differentIsland:
        // Semua opsi tersedia
        for (int i = 0; i < _standardShippingOptions.length; i++) {
          final option = _standardShippingOptions[i];
          standardOptions.add(ShippingCost.standardOption(
            service: option.service,
            description: option.description,
            cost: _calculateStandardCost(option, weight),
            etd: option.etd,
          ));
        }

        // Tambahkan opsi cargo untuk pulau lain (murah tapi lama)
        standardOptions.add(ShippingCost.standardOption(
          service: 'CARGO',
          description: 'Pengiriman cargo ekonomis antar pulau',
          cost: (_calculateStandardCost(_standardShippingOptions[2], weight) *
                  0.8)
              .round(),
          etd: '7-14',
        ));
        break;
    }

    // Urutkan berdasarkan harga (termurah dulu)
    standardOptions.sort((a, b) => a.cost.compareTo(b.cost));

    return standardOptions;
  }

  /// Mendapatkan semua kota
  static Future<List<RajaOngkirCity>> getAllCities() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/city'),
        headers: {
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rajaongkir']['status']['code'] == 200) {
          final cities = (data['rajaongkir']['results'] as List)
              .map((city) => RajaOngkirCity.fromJson(city))
              .toList();
          return cities;
        } else {
          throw Exception(
              'RajaOngkir API Error: ${data['rajaongkir']['status']['description']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting all cities: $e');
      rethrow;
    }
  }

  /// Mencari kota berdasarkan nama
  static Future<List<RajaOngkirCity>> searchCities(String cityName) async {
    try {
      final allCities = await getAllCities();
      return allCities
          .where((city) =>
              city.cityName.toLowerCase().contains(cityName.toLowerCase()) ||
              city.provinceName.toLowerCase().contains(cityName.toLowerCase()))
          .toList();
    } catch (e) {
      print('Error searching cities: $e');
      return [];
    }
  }

  /// Mendapatkan kota berdasarkan ID
  static Future<RajaOngkirCity?> getCityById(String cityId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/city?id=$cityId'),
        headers: {
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rajaongkir']['status']['code'] == 200) {
          final results = data['rajaongkir']['results'] as List;
          if (results.isNotEmpty) {
            return RajaOngkirCity.fromJson(results.first);
          }
        }
      }
      return null;
    } catch (e) {
      print('Error getting city by ID: $e');
      return null;
    }
  }

  /// Mendapatkan semua provinsi
  static Future<List<Map<String, dynamic>>> getAllProvinces() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/province'),
        headers: {
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rajaongkir']['status']['code'] == 200) {
          return List<Map<String, dynamic>>.from(data['rajaongkir']['results']);
        }
      }
      return [];
    } catch (e) {
      print('Error getting provinces: $e');
      return [];
    }
  }

  /// Mendapatkan kota berdasarkan provinsi
  static Future<List<RajaOngkirCity>> getCitiesByProvince(
      String provinceId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/city?province=$provinceId'),
        headers: {
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rajaongkir']['status']['code'] == 200) {
          final cities = (data['rajaongkir']['results'] as List)
              .map((city) => RajaOngkirCity.fromJson(city))
              .toList();
          return cities;
        }
      }
      return [];
    } catch (e) {
      print('Error getting cities by province: $e');
      return [];
    }
  }

  /// Mendapatkan ongkos kirim untuk satu kurir
  static Future<List<ShippingCost>> getShippingCostsByCourier({
    required String destinationCityId,
    required int weight, // dalam gram
    required String courier, // jne, pos, tiki
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/cost'),
        headers: {
          'key': _apiKey,
          'content-type': 'application/x-www-form-urlencoded',
        },
        body: {
          'origin': _originCityId,
          'destination': destinationCityId,
          'weight': weight.toString(),
          'courier': courier,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rajaongkir']['status']['code'] == 200) {
          final results = data['rajaongkir']['results'] as List;
          if (results.isNotEmpty) {
            final costs = (results[0]['costs'] as List)
                .map((cost) => ShippingCost.fromJson(cost, courier))
                .toList();
            return costs;
          }
        } else {
          print(
              'RajaOngkir API Error: ${data['rajaongkir']['status']['description']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('Error getting shipping costs for $courier: $e');
      return [];
    }
  }

  /// Mendapatkan semua ongkos kirim dari semua kurir dengan fallback ke opsi standar
  static Future<List<ShippingCost>> getAllShippingCosts({
    required String destinationCityId,
    required int weight,
    List<String>? couriers,
    String? destinationProvince, // Tambahan untuk opsi standar
  }) async {
    final defaultCouriers = couriers ?? ['jne', 'pos', 'tiki'];
    final allShippingCosts = <ShippingCost>[];

    // Coba dapatkan ongkos kirim dari API RajaOngkir
    for (String courier in defaultCouriers) {
      try {
        final costs = await getShippingCostsByCourier(
          destinationCityId: destinationCityId,
          weight: weight,
          courier: courier,
        );
        allShippingCosts.addAll(costs);
      } catch (e) {
        print('Error getting costs for $courier: $e');
        // Continue dengan kurir lainnya
      }
    }

    // Jika tidak ada hasil dari API atau sebagai tambahan, gunakan opsi standar
    if (destinationProvince != null) {
      final standardOptions = getStandardShippingOptions(
        destinationProvince: destinationProvince,
        weight: weight,
      );

      // Jika tidak ada hasil dari API sama sekali, gunakan opsi standar
      if (allShippingCosts.isEmpty) {
        allShippingCosts.addAll(standardOptions);
      } else {
        // Tambahkan opsi standar sebagai alternatif
        allShippingCosts.addAll(standardOptions);
      }
    }

    // Urutkan berdasarkan harga (termurah dulu)
    allShippingCosts.sort((a, b) => a.cost.compareTo(b.cost));

    return allShippingCosts;
  }

  /// Mendapatkan ongkos kirim berdasarkan estimasi pengiriman
  static Future<List<ShippingCost>> getShippingCostsByDeliveryTime({
    required String destinationCityId,
    required int weight,
    String? destinationProvince,
    bool prioritizeSpeed =
        false, // true untuk yang tercepat, false untuk termurah
  }) async {
    final allCosts = await getAllShippingCosts(
      destinationCityId: destinationCityId,
      weight: weight,
      destinationProvince: destinationProvince,
    );

    if (prioritizeSpeed) {
      // Urutkan berdasarkan estimasi waktu pengiriman (tercepat dulu)
      allCosts.sort((a, b) {
        final aEtd = _parseEtd(a.etd);
        final bEtd = _parseEtd(b.etd);
        return aEtd.compareTo(bEtd);
      });
    }

    return allCosts;
  }

  /// Helper method untuk parsing ETD
  static int _parseEtd(String etd) {
    // Mengubah "2-3" menjadi 2, "1-2" menjadi 1, dll
    final parts = etd.split('-');
    if (parts.isNotEmpty) {
      return int.tryParse(parts.first) ?? 99;
    }
    return 99;
  }

  /// Validasi API Key
  static Future<bool> validateApiKey() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/province'),
        headers: {
          'key': _apiKey,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rajaongkir']['status']['code'] == 200;
      }
      return false;
    } catch (e) {
      print('Error validating API key: $e');
      return false;
    }
  }

  /// Mendapatkan informasi kota asal (Bondowoso)
  static Future<RajaOngkirCity?> getOriginCity() async {
    return await getCityById(_originCityId);
  }

  /// Mencari kota dengan fuzzy search (lebih toleran terhadap typo)
  static Future<List<RajaOngkirCity>> fuzzySearchCities(String query) async {
    try {
      final allCities = await getAllCities();
      final lowerQuery = query.toLowerCase();

      // Exact match first
      final exactMatches = allCities
          .where((city) =>
              city.cityName.toLowerCase() == lowerQuery ||
              city.provinceName.toLowerCase() == lowerQuery)
          .toList();

      // Starts with match
      final startsWithMatches = allCities
          .where((city) =>
              city.cityName.toLowerCase().startsWith(lowerQuery) ||
              city.provinceName.toLowerCase().startsWith(lowerQuery))
          .toList();

      // Contains match
      final containsMatches = allCities
          .where((city) =>
              city.cityName.toLowerCase().contains(lowerQuery) ||
              city.provinceName.toLowerCase().contains(lowerQuery))
          .toList();

      // Combine and remove duplicates
      final result = <RajaOngkirCity>[];
      result.addAll(exactMatches);
      result.addAll(startsWithMatches.where((city) => !result.contains(city)));
      result.addAll(containsMatches.where((city) => !result.contains(city)));

      return result;
    } catch (e) {
      print('Error in fuzzy search: $e');
      return [];
    }
  }

  /// Mendapatkan estimasi total biaya pengiriman berdasarkan berat dan kuantitas
  static Future<Map<String, dynamic>> calculateShippingEstimate({
    required String destinationCityId,
    required int itemWeight, // berat per item dalam gram
    required int quantity,
    String? preferredCourier,
    String? destinationProvince,
  }) async {
    try {
      final totalWeight = itemWeight * quantity;
      final destinationCity = await getCityById(destinationCityId);

      List<ShippingCost> shippingOptions;

      if (preferredCourier != null) {
        shippingOptions = await getShippingCostsByCourier(
          destinationCityId: destinationCityId,
          weight: totalWeight,
          courier: preferredCourier,
        );
      } else {
        shippingOptions = await getAllShippingCosts(
          destinationCityId: destinationCityId,
          weight: totalWeight,
          destinationProvince: destinationProvince,
        );
      }

      if (shippingOptions.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada opsi pengiriman tersedia',
        };
      }

      // Ambil opsi termurah dan tercepat
      final cheapestOption =
          shippingOptions.reduce((a, b) => a.cost < b.cost ? a : b);
      final fastestOption = shippingOptions
          .reduce((a, b) => _parseEtd(a.etd) < _parseEtd(b.etd) ? a : b);

      return {
        'success': true,
        'destination': destinationCity?.toString() ?? 'Unknown',
        'totalWeight': totalWeight,
        'allOptions': shippingOptions,
        'cheapestOption': cheapestOption,
        'fastestOption': fastestOption,
        'recommendedOption': cheapestOption, // Bisa diubah logikanya
        'hasStandardOptions':
            shippingOptions.any((option) => option.isStandardOption),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error calculating shipping: $e',
      };
    }
  }

  /// Mendapatkan opsi pengiriman dengan fallback lengkap
  static Future<List<ShippingCost>> getShippingOptionsWithFallback({
    required String destinationCityName,
    required String destinationProvince,
    required int weight,
  }) async {
    try {
      // Coba cari kota di API RajaOngkir
      final cities = await fuzzySearchCities(destinationCityName);

      if (cities.isNotEmpty) {
        // Jika kota ditemukan, gunakan API RajaOngkir + opsi standar
        final city = cities.first;
        return await getAllShippingCosts(
          destinationCityId: city.cityId,
          weight: weight,
          destinationProvince: destinationProvince,
        );
      } else {
        // Jika kota tidak ditemukan, gunakan hanya opsi standar
        return getStandardShippingOptions(
          destinationProvince: destinationProvince,
          weight: weight,
        );
      }
    } catch (e) {
      print('Error in getShippingOptionsWithFallback: $e');
      // Fallback terakhir ke opsi standar
      return getStandardShippingOptions(
        destinationProvince: destinationProvince,
        weight: weight,
      );
    }
  }
}
