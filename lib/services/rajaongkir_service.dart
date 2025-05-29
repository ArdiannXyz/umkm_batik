import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/rajaongkir.dart';

class RajaOngkirService {
  static const String _apiKey = '07fZMEpQac09f0c021badd62rM1OXCwt';
  static const String _baseUrl = 'https://collaborator.komerce.id/rates';
  static const String _originCityId = '45';
  static const String _originProvince = 'JAWA TIMUR';
  static List<RajaOngkirCity>? _cachedCities;
  static List<Map<String, dynamic>>? _cachedProvinces;
  static Future<List<RajaOngkirCity>> getAllCities() async {
    if (_cachedCities != null) {
      return _cachedCities!;
    }
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/city'),
        headers: {
          'key': _apiKey,
          'Content-Type': 'application/json',
        },
      );
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rajaongkir']['status']['code'] == 200) {
          final cities = (data['rajaongkir']['results'] as List)
              .map((city) => RajaOngkirCity.fromJson(city))
              .toList();
          _cachedCities = cities;
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

  static Future<List<Map<String, dynamic>>> getAllProvinces() async {
    if (_cachedProvinces != null) {
      return _cachedProvinces!;
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/province'),
        headers: {
          'key': _apiKey,
          'Content-Type': 'application/json',
        },
      );

      print('Province response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rajaongkir']['status']['code'] == 200) {
          final provinces = List<Map<String, dynamic>>.from(data['rajaongkir']['results']);
          _cachedProvinces = provinces;
          return provinces;
        } else {
          throw Exception(
              'RajaOngkir API Error: ${data['rajaongkir']['status']['description']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting provinces: $e');
      return [];
    }
  }

  static Future<List<RajaOngkirCity>> searchCities(String cityName) async {
    try {
      final allCities = await getAllCities();
      final lowerCityName = cityName.toLowerCase().trim();
      final exactMatches = allCities
          .where((city) => city.cityName.toLowerCase() == lowerCityName)
          .toList();
      
      if (exactMatches.isNotEmpty) return exactMatches;
      
      final startsWithMatches = allCities
          .where((city) => city.cityName.toLowerCase().startsWith(lowerCityName))
          .toList();
      
      if (startsWithMatches.isNotEmpty) return startsWithMatches;
      
      final containsMatches = allCities
          .where((city) => 
              city.cityName.toLowerCase().contains(lowerCityName) ||
              city.provinceName.toLowerCase().contains(lowerCityName))
          .toList();
      
      return containsMatches;
    } catch (e) {
      print('Error searching cities: $e');
      return [];
    }
  }

  static Future<RajaOngkirCity?> getCityById(String cityId) async {
    try {
      final allCities = await getAllCities();
      return allCities.firstWhere(
        (city) => city.cityId == cityId,
        orElse: () => throw Exception('City not found'),
      );
    } catch (e) {
      print('Error getting city by ID: $e');
      return null;
    }
  }

  static Future<List<RajaOngkirCity>> getCitiesByProvince(String provinceId) async {
    try {
      final allCities = await getAllCities();
      return allCities
          .where((city) => city.provinceName == provinceId)
          .toList();
    } catch (e) {
      print('Error getting cities by province: $e');
      return [];
    }
  }

  static Future<List<ShippingCost>> getShippingCostsByCity({
    required String destinationCityId,
    required int weight,
    List<String>? couriers,
  }) async {
    final defaultCouriers = couriers ?? ['jne', 'pos', 'tiki', 'jnt', 'sicepat', 'anteraja'];
    final allShippingCosts = <ShippingCost>[];

    print('Getting shipping costs for city ID: $destinationCityId, weight: ${weight}g');

    for (String courier in defaultCouriers) {
      try {
        final costs = await _getShippingCostsByCourier(
          destinationCityId: destinationCityId,
          weight: weight,
          courier: courier,
        );
        
        if (costs.isNotEmpty) {
          allShippingCosts.addAll(costs);
          print('Added ${costs.length} options from $courier');
        }
      } catch (e) {
        print('Failed to get costs from $courier: $e');
        continue;
      }
    }

    if (allShippingCosts.isEmpty) {
      print('No shipping costs found from API');
      return [];
    }

    // Urutkan berdasarkan harga
    allShippingCosts.sort((a, b) => a.cost.compareTo(b.cost));
    
    print('Total shipping options found: ${allShippingCosts.length}');
    return allShippingCosts;
  }

  static Future<List<ShippingCost>> _getShippingCostsByCourier({
    required String destinationCityId,
    required int weight,
    required String courier,
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
          if (results.isNotEmpty && results[0]['costs'] != null) {
            final costs = (results[0]['costs'] as List)
                .map((cost) => ShippingCost.fromJson(cost, courier))
                .toList();
            return costs;
          }
        } else {
          print('RajaOngkir API Error for $courier: ${data['rajaongkir']['status']['description']}');
        }
      } else {
        print('HTTP Error for $courier: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('Exception getting shipping costs for $courier: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getShippingCostsByAddress({
    required String cityName,
    required String provinceName,
    required int weight,
    List<String>? preferredCouriers,
  }) async {
    try {
      print('Getting shipping costs for: $cityName, $provinceName');
      final cities = await searchCities(cityName);
      
      if (cities.isEmpty) {
        return {
          'success': false,
          'message': 'Kota "$cityName" tidak ditemukan',
          'shippingOptions': <ShippingCost>[],
        };
      }

      RajaOngkirCity? selectedCity;
      if (provinceName.isNotEmpty) {
        final provinceLower = provinceName.toLowerCase();
        selectedCity = cities.firstWhere(
          (city) => city.provinceName.toLowerCase().contains(provinceLower),
          orElse: () => cities.first,
        );
      } else {
        selectedCity = cities.first;
      }

      print('Selected city: ${selectedCity.cityName}, ${selectedCity.provinceName}');

      final shippingOptions = await getShippingCostsByCity(
        destinationCityId: selectedCity.cityId,
        weight: weight,
        couriers: preferredCouriers,
      );

      if (shippingOptions.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada opsi pengiriman tersedia untuk ${selectedCity.cityName}',
          'selectedCity': selectedCity,
          'shippingOptions': <ShippingCost>[],
        };
      }

      // Analisis opsi pengiriman
      final cheapestOption = shippingOptions.reduce((a, b) => a.cost < b.cost ? a : b);
      final fastestOption = shippingOptions.reduce((a, b) => _parseEtd(a.etd) < _parseEtd(b.etd) ? a : b);

      return {
        'success': true,
        'selectedCity': selectedCity,
        'totalWeight': weight,
        'shippingOptions': shippingOptions,
        'cheapestOption': cheapestOption,
        'fastestOption': fastestOption,
        'alternativeCities': cities.length > 1 ? cities.skip(1).take(3).toList() : [],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
        'shippingOptions': <ShippingCost>[],
      };
    }
  }
  static Future<Map<String, dynamic>> getShippingEstimateWithCityOptions({
    required String cityName,
    required int weight,
    int maxCityOptions = 5,
  }) async {
    try {
      final cities = await searchCities(cityName);
      
      if (cities.isEmpty) {
        return {
          'success': false,
          'message': 'Tidak ada kota yang ditemukan untuk "$cityName"',
        };
      }

      final cityOptions = <Map<String, dynamic>>[];
      
      final limitedCities = cities.take(maxCityOptions).toList();
      
      for (final city in limitedCities) {
        try {
          final shippingCosts = await getShippingCostsByCity(
            destinationCityId: city.cityId,
            weight: weight,
          );
          
          if (shippingCosts.isNotEmpty) {
            final cheapest = shippingCosts.reduce((a, b) => a.cost < b.cost ? a : b);
            
            cityOptions.add({
              'city': city,
              'cheapestCost': cheapest.cost,
              'cheapestService': cheapest.service,
              'optionsCount': shippingCosts.length,
              'allOptions': shippingCosts,
            });
          }
        } catch (e) {
          print('Error getting costs for ${city.cityName}: $e');
        }
      }

      cityOptions.sort((a, b) => a['cheapestCost'].compareTo(b['cheapestCost']));

      return {
        'success': true,
        'searchQuery': cityName,
        'totalCitiesFound': cities.length,
        'cityOptions': cityOptions,
        'recommendedCity': cityOptions.isNotEmpty ? cityOptions.first : null,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  static int _parseEtd(String etd) {
    try {
      final cleaned = etd.replaceAll(RegExp(r'[^0-9\-]'), '');
      if (cleaned.contains('-')) {
        final parts = cleaned.split('-');
        return int.parse(parts.first);
      }
      return int.parse(cleaned);
    } catch (_) {
      return 999;
    }
  }

  static Future<bool> validateApiKey() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/province'),
        headers: {
          'key': _apiKey,
          'Content-Type': 'application/json',
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

  static Future<RajaOngkirCity?> getOriginCity() async {
    return await getCityById(_originCityId);
  }
  static Future<List<RajaOngkirCity>> fuzzySearchCities(String query) async {
    try {
      final allCities = await getAllCities();
      final lowerQuery = query.toLowerCase().trim();

      if (lowerQuery.isEmpty) return [];

      final results = <RajaOngkirCity>[];
      final scores = <int>[];

      for (final city in allCities) {
        final cityNameLower = city.cityName.toLowerCase();
        final provinceNameLower = city.provinceName.toLowerCase();
        
        int score = 0;

        if (cityNameLower == lowerQuery) {
          score = 1000;
        } else if (provinceNameLower == lowerQuery) {
          score = 900;
        }
        else if (cityNameLower.startsWith(lowerQuery)) {
          score = 800;
        } else if (provinceNameLower.startsWith(lowerQuery)) {
          score = 700;
        }
        // Contains match
        else if (cityNameLower.contains(lowerQuery)) {
          score = 600;
        } else if (provinceNameLower.contains(lowerQuery)) {
          score = 500;
        }

        if (score > 0) {
          results.add(city);
          scores.add(score);
        }
      }

      final indices = List.generate(results.length, (i) => i);
      indices.sort((a, b) => scores[b].compareTo(scores[a]));
      
      return indices.map((i) => results[i]).toList();
    } catch (e) {
      print('Error in fuzzy search: $e');
      return [];
    }
  }

  static void clearCache() {
    _cachedCities = null;
    _cachedProvinces = null;
  }

  static Future<Map<String, dynamic>> getShippingSummary({
    required String cityName,
    required String provinceName,
    required List<Map<String, dynamic>> items, 
  }) async {
    try {
      int totalWeight = 0;
      for (final item in items) {
        final weight = item['weight'] as int? ?? 0;
        final quantity = item['quantity'] as int? ?? 1;
        totalWeight += (weight * quantity);
      }

      if (totalWeight == 0) {
        return {
          'success': false,
          'message': 'Total berat tidak boleh 0',
        };
      }
      final result = await getShippingCostsByAddress(
        cityName: cityName,
        provinceName: provinceName,
        weight: totalWeight,
      );

      if (result['success']) {
        final shippingOptions = result['shippingOptions'] as List<ShippingCost>;
        
        return {
          'success': true,
          'destination': result['selectedCity'],
          'totalWeight': totalWeight,
          'totalItems': items.length,
          'shippingOptions': shippingOptions,
          'cheapestOption': result['cheapestOption'],
          'fastestOption': result['fastestOption'],
          'priceRange': shippingOptions.isNotEmpty ? {
            'min': shippingOptions.map((e) => e.cost).reduce((a, b) => a < b ? a : b),
            'max': shippingOptions.map((e) => e.cost).reduce((a, b) => a > b ? a : b),
          } : null,
        };
      } else {
        return result;
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error calculating shipping summary: $e',
      };
    }
  }
}