import 'package:flutter/material.dart';
import 'pilih_alamat_page.dart';
import 'pesanan_page.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  // Tambahkan variabel untuk menyimpan objek Address yang dipilih
  Address? selectedAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDEF1FF), // Background biru muda
      appBar: AppBar(
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0D6EFD),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildSection(
                child: InkWell(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PilihAlamatPage()),
                    );

                    if (result != null && result is Address) {
                      setState(() {
                        selectedAddress = result;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedAddress?.namaLengkap ?? "Pilih Alamat",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              selectedAddress != null
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(selectedAddress!.alamatLengkap),
                                        Text(
                                          "${selectedAddress!.kecamatan}, ${selectedAddress!.kota}, ${selectedAddress!.provinsi}",
                                        ),
                                        Text(
                                            "Kode Pos: ${selectedAddress!.kodePos}"),
                                        Text(
                                            "No. HP: ${selectedAddress!.nomorHp}"),
                                      ],
                                    )
                                  : const Text(
                                      "Tap untuk memilih alamat pengiriman",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
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
                child: const ListTile(
                  title: Text("Informasi Pengiriman"),
                  trailing: Text("Rp.15.000"),
                  leading: Radio(
                    value: true,
                    groupValue: true,
                    onChanged: null,
                  ),
                  subtitle: Text("JNE"),
                ),
              ),
              const SizedBox(height: 12),
              _buildSection(
                child: const ListTile(
                  title: Text("Metode Pembayaran"),
                  leading: Radio(
                    value: true,
                    groupValue: true,
                    onChanged: null,
                  ),
                  subtitle: Text("MidTrans"),
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
              const SizedBox(
                  height: 100), // Spasi supaya tidak ketutupan tombol
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        height: 70,
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Total : 419.000",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D6EFD),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: selectedAddress == null
                  ? null // Disable button jika alamat belum dipilih
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Pesanan berhasil dibuat!")),
                      );
                      Future.delayed(const Duration(seconds: 1), () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PesananPage()),
                        );
                      });
                    },
              child: const Text(
                "Buat Pesanan",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
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
        children: [Text(left), Text(right)],
      ),
    );
  }
}
