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

  String get displayName => '$courier$service';
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