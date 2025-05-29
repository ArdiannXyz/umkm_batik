import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditUlasanPage extends StatefulWidget {
  final int productId;
  final Map<String, dynamic> existingReview;

  const EditUlasanPage({
    super.key,
    required this.productId,
    required this.existingReview,
  });

  @override
  State<EditUlasanPage> createState() => _EditUlasanPageState();
}

class _EditUlasanPageState extends State<EditUlasanPage> {
  int selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();
  int? userId;
  bool isSubmitting = false;
  bool isDeleting = false;
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize with existing review data
    selectedRating =
        int.tryParse(widget.existingReview['rating'].toString()) ?? 0;
    _reviewController.text = widget.existingReview['komentar'] ?? '';
    loadUserId();
  }

  Future<void> loadUserId() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');

      if (id == null) {
        setState(() {
          errorMessage = 'Silakan login terlebih dahulu';
          isLoading = false;
        });
        return;
      }

      setState(() {
        userId = id;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat memuat data';
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> updateReview() async {
    if (selectedRating == 0 ||
        _reviewController.text.isEmpty ||
        userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Harap isi semua bidang dan pilih rating')),
      );
      return;
    }

    setState(() => isSubmitting = true);

    final url = Uri.parse("http://192.168.1.6/umkm_batik/API/edit_reviews.php");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-HTTP-Method-Override": "PUT" // Override untuk PHP
        },
        body: jsonEncode({
          'review_id': widget.existingReview['id'],
          'product_id': widget.productId,
          'user_id': userId,
          'rating': selectedRating,
          'komentar': _reviewController.text,
        }),
      );

      setState(() => isSubmitting = false);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['message'] != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          Navigator.pop(
              context, true); // Return true to indicate successful update
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['error'] ?? 'Gagal memperbarui ulasan')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> deleteReview() async {
    // Konfirmasi penghapusan
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus ulasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || userId == null) return;

    setState(() => isDeleting = true);

    final url = Uri.parse("http://192.168.1.6/umkm_batik/API/delete_reviews.php");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "X-HTTP-Method-Override": "DELETE" // Override untuk PHP
        },
        body: jsonEncode({
          'product_id': widget.productId,
          'user_id': userId,
        }),
      );

      setState(() => isDeleting = false);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Ulasan berhasil dihapus')),
        );
        Navigator.pop(
            context, true); // Return true to indicate successful deletion
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error: ${response.statusCode} - ${response.body}')),
        );
      }
    } catch (e) {
      setState(() => isDeleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: AppBar(
        title: const Text(
          'Edit ulasan',
          style: TextStyle(color: Colors.white), // Perbaikan di sini
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Kembali'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildEditForm(),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Rating bintang
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        selectedRating = index + 1;
                      });
                    },
                    icon: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      size: 35,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // TextField ulasan
          TextField(
            controller: _reviewController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Deskripsikan Pengalaman Anda',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          const Spacer(),

          // Tombol Update
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting || isDeleting ? null : updateReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Simpan Perubahan',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Hapus
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSubmitting || isDeleting ? null : deleteReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isDeleting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Hapus Ulasan',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
