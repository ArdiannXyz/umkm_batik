import 'package:flutter/material.dart';
import 'pilih_alamat_page.dart';
import 'pesanan_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String alamat = "Ado Chann"; // Alamat default

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA), // Background biru muda
      appBar: AppBar(
        title: const Text("Checkout"),
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true, // Supaya title di tengah
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.blue),
                  title: Text(alamat), // Alamat yang diupdate
                  subtitle: const Text(
                      "Sukoreno gang 6 ketimur toko tingkat selatan jalan UMBULSARI,KAB Jember,JAWA TIMUR"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    // Navigasi ke halaman PilihAlamatPage dan tunggu hasilnya
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PilihAlamatPage()),
                    );

                    if (result != null) {
                      // Jika ada hasil, update alamat
                      setState(() {
                        alamat = result;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/batikpng.jpg',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Batik Jeruk",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("2x"),
                          Text("Rp.200.000"),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: ListTile(
                  title: const Text("Informasi Pengiriman"),
                  trailing: const Text("Rp.15.000"),
                  leading: const Radio(
                    value: true,
                    groupValue: true,
                    onChanged: null,
                  ),
                  subtitle: const Text("JNE"),
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: ListTile(
                  title: const Text("Metode Pembayaran"),
                  leading: const Radio(
                    value: true,
                    groupValue: true,
                    onChanged: null,
                  ),
                  subtitle: const Text("MidTrans"),
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Rincian Pembayaran",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 8),
                    _RowText("Subtotal untuk produk", "Rp.400.000"),
                    _RowText("Subtotal untuk pengiriman", "Rp.15.000"),
                    _RowText("Biaya layanan", "Rp.4.000"),
                    Divider(),
                    _RowText("Total Pembayaran", "Rp.419.000"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total : 419.000"),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                        ),
                        onPressed: () {
                          // Tampilkan snackbar dulu
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Pesanan berhasil dibuat!")),
                          );

                          // Delay sedikit supaya Snackbar sempat muncul
                          Future.delayed(const Duration(seconds: 1), () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PesananPage()),
                            );
                          });
                        },
                        child: const Text("Buat Pesanan",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // Putih untuk section card
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _RowText extends StatelessWidget {
  final String left;
  final String right;

  const _RowText(this.left, this.right);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(left), Text(right)],
      ),
    );
  }
}
