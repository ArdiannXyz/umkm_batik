// payment_method.dart
enum PaymentMethod {
  shopee,
  dana,
  bca,
  mandiri,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.shopee:
        return 'ShopeePay';
      case PaymentMethod.dana:
        return 'DANA';
      case PaymentMethod.bca:
        return 'Bank BCA';
      case PaymentMethod.mandiri:
        return 'Bank Mandiri';
    }
  }

  String get accountNumber {
    switch (this) {
      case PaymentMethod.shopee:
      case PaymentMethod.dana:
        return '089612345678';
      case PaymentMethod.bca:
      case PaymentMethod.mandiri:
        return '8962829292101010';
    }
  }

  List<String> get instructions {
    switch (this) {
      case PaymentMethod.shopee:
        return [
          'Buka aplikasi ShopeePay di ponsel Anda',
          'Pilih "Scan" di halaman utama',
          'Scan kode QR yang ditampilkan di layar',
          'Periksa detail pembayaran dan masukkan PIN',
          'Konfirmasi pembayaran dan selesai'
        ];
      case PaymentMethod.dana:
        return [
          'Buka aplikasi DANA di ponsel Anda',
          'Pilih opsi "Scan" atau "Pay"',
          'Scan kode QR yang ditampilkan',
          'Masukkan nominal yang sesuai dengan total pembayaran',
          'Konfirmasi pembayaran dengan PIN DANA',
          'Simpan bukti transaksi'
        ];
      case PaymentMethod.bca:
        return [
          'Salin no. rekening bank di atas',
          'Buka aplikasi BCA mobile yang digunakan',
          'Pilih menu "m-Transfer"',
          'Pilih "Transfer ke BCA"',
          'Masukkan nomor rekening tujuan',
          'Masukkan nominal yang sesuai dengan total pembayaran',
          'Masukkan id pemesanan pada kolom berita/keterangan "wajib*"',
          'Periksa kembali detail transfer dan konfirmasi'
        ];
      case PaymentMethod.mandiri:
        return [
          'Salin no. rekening bank di atas',
          'Buka aplikasi Livin\' by Mandiri yang digunakan',
          'Pilih fitur "Transfer"',
          'Pilih "Ke rekening Mandiri"',
          'Tempel no. rekening bank pada kolom',
          'Klik "ok" lalu masukkan nominal yang sesuai dengan total pembayaran',
          'Masukkan id pemesanan pada kolom catatan "wajib*"',
          'Verifikasi lalu bayar'
        ];
    }
  }
}
