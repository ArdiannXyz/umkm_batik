class Address {
  final int id;
  final int userId;
  final String namaLengkap;
  final String nomorHp;
  final String provinsi;
  final String kota;
  final String kecamatan;
  final int kodePos;
  final String alamatLengkap;
  final String createdAt;

  Address({
    required this.id,
    required this.userId,
    required this.namaLengkap,
    required this.nomorHp,
    required this.provinsi,
    required this.kota,
    required this.kecamatan,
    required this.kodePos,
    required this.alamatLengkap,
    required this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userId: json['user_id'],
      namaLengkap: json['nama_lengkap'],
      nomorHp: json['nomor_hp'],
      provinsi: json['provinsi'],
      kota: json['kota'],
      kecamatan: json['kecamatan'],
      kodePos: json['kode_pos'],
      alamatLengkap: json['alamat_lengkap'],
      createdAt: json['created_at'],
    );
  }
}
