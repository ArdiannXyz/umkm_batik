// models/binderbyte_models.dart

class BinderByteProvince {
  final String id;
  final String name;

  BinderByteProvince({
    required this.id,
    required this.name,
  });

  factory BinderByteProvince.fromJson(Map<String, dynamic> json) {
    return BinderByteProvince(
      id: json['id'].toString(),
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class BinderByteCity {
  final String id;
  final String name;
  final String provinceId;

  BinderByteCity({
    required this.id,
    required this.name,
    required this.provinceId,
  });

  factory BinderByteCity.fromJson(Map<String, dynamic> json) {
    return BinderByteCity(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      provinceId: json['province_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province_id': provinceId,
    };
  }
}

class BinderByteDistrict {
  final String id;
  final String name;
  final String cityId;

  BinderByteDistrict({
    required this.id,
    required this.name,
    required this.cityId,
  });

  factory BinderByteDistrict.fromJson(Map<String, dynamic> json) {
    return BinderByteDistrict(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      cityId: json['city_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city_id': cityId,
    };
  }
}

class BinderByteVillage {
  final String id;
  final String name;
  final String districtId;

  BinderByteVillage({
    required this.id,
    required this.name,
    required this.districtId,
  });

  factory BinderByteVillage.fromJson(Map<String, dynamic> json) {
    return BinderByteVillage(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      districtId: json['district_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'district_id': districtId,
    };
  }
}

class BinderByteShippingCost {
  final String service;
  final String description;
  final int cost;
  final String etd;
  final String courier;

  BinderByteShippingCost({
    required this.service,
    required this.description,
    required this.cost,
    required this.etd,
    required this.courier,
  });

  factory BinderByteShippingCost.fromJson(Map<String, dynamic> json) {
    return BinderByteShippingCost(
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      cost: int.tryParse(json['cost'].toString()) ?? 0,
      etd: json['etd'] ?? '',
      courier: json['courier'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'description': description,
      'cost': cost,
      'etd': etd,
      'courier': courier,
    };
  }

  String get displayName => '$courier ${service.toUpperCase()}';
  String get fullDescription => '$description (${etd} hari)';
}

class BinderByteTrackingResult {
  final String waybill;
  final String courier;
  final String service;
  final String status;
  final String date;
  final String desc;
  final String weight;
  final List<BinderByteTrackingHistory> history;

  BinderByteTrackingResult({
    required this.waybill,
    required this.courier,
    required this.service,
    required this.status,
    required this.date,
    required this.desc,
    required this.weight,
    required this.history,
  });

  factory BinderByteTrackingResult.fromJson(Map<String, dynamic> json) {
    return BinderByteTrackingResult(
      waybill: json['waybill'] ?? '',
      courier: json['courier'] ?? '',
      service: json['service'] ?? '',
      status: json['status'] ?? '',
      date: json['date'] ?? '',
      desc: json['desc'] ?? '',
      weight: json['weight'] ?? '',
      history: (json['history'] as List<dynamic>?)
              ?.map((item) => BinderByteTrackingHistory.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class BinderByteTrackingHistory {
  final String date;
  final String desc;
  final String location;

  BinderByteTrackingHistory({
    required this.date,
    required this.desc,
    required this.location,
  });

  factory BinderByteTrackingHistory.fromJson(Map<String, dynamic> json) {
    return BinderByteTrackingHistory(
      date: json['date'] ?? '',
      desc: json['desc'] ?? '',
      location: json['location'] ?? '',
    );
  }
}

class BinderByteApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final int? code;

  BinderByteApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.code,
  });

  factory BinderByteApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return BinderByteApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
      code: json['code'],
    );
  }
}
