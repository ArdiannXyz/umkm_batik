import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DetailPesananPage extends StatelessWidget {
  const DetailPesananPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text("Detail Pemesanan"),
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Info Pengiriman",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const _RowText("Status", "Dikirim"),
                    const _RowText("Kurir", "JNE"),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("No Resi : JNEID000228363"),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                                const ClipboardData(text: "JNEID000228363"));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("No Resi disalin")),
                            );
                          },
                        ),
                      ],
                    ),
                    const _RowText("Metode Pembayaran", "Bank Transfer"),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text("Alamat Pengiriman",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text(
                            "Sukoreno gang 6 ketimur toko tingkat selatan jalan UMBULSARI,KAB Jember,JAWA TIMUR",
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Batik Jeruk",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text("2x"),
                        SizedBox(height: 4),
                        Text("Rp.200.000"),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Rincian Pembayaran",
                        style: TextStyle(fontWeight: FontWeight.bold)),
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
              ElevatedButton.icon(
                onPressed: () {
                  // Navigasi ke halaman bantuan atau lainnya
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Fitur Bantuan belum tersedia")),
                  );
                },
                icon: const Icon(Icons.help_outline),
                label: const Text("Bantuan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
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
        color: Colors.white,
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
        children: [
          Text(left),
          Text(right),
        ],
      ),
    );
  }
}
