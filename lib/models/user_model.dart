// lib/models/user_model.dart
class User {
  final String nama;
  final String email;
  final String noHp;

  User({
    required this.nama,
    required this.email,
    required this.noHp,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nama: json['nama'],
      email: json['email'],
      noHp: json['no_hp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nama': nama,
      'email': email,
      'no_hp': noHp,
    };
  }
}
