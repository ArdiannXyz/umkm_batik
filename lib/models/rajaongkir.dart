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