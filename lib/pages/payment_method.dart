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
        return '085746827426';
      case PaymentMethod.dana:
        return '085746928426';
      case PaymentMethod.bca:
        return '1210896372';
      case PaymentMethod.mandiri:
        return '8962829292101010';
    }
  }

  List<String> get instructions {
    switch (this) {
      case PaymentMethod.shopee:
        return [
          'Buka aplikasi ShopeePay di ponsel Anda',
          'Pilih transfter di halaman utama',
          'Copy nomer Shopeepay diatas',
          'Pastikan memberikan catatan ID pemesanan!',
          'Konfirmasi pembayaran dan selesai',
          'Simpan bukti transaksi'
        ];
      case PaymentMethod.dana:
        return [
          'Buka aplikasi DANA di ponsel Anda',
          'Pilih transfter di halaman utama"',
          'Copy nomer Dana diatas',
          'Pastikan memberikan catatan ID pemesanan!',
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
