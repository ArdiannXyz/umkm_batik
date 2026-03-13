import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/review_service.dart';

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
      const SnackBar(content: Text('Harap isi semua bidang dan pilih rating')),
    );
    return;
  }

  setState(() => isSubmitting = true);

  final result = await ReviewService.updateReview(
    reviewId: widget.existingReview['id'],
    productId: widget.productId,
    userId: userId!,
    rating: selectedRating,
    komentar: _reviewController.text,
  );

  setState(() => isSubmitting = false);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'])),
  );

  if (result['success']) {
    Navigator.pop(context, true);
  }
}


Future<void> deleteReview() async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.help_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Konfirmasi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Yakin ingin menghapus ulasan ini?',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6), // Sudut sedikit membulat
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6), // Sama seperti tombol "Batal"
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.white),
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

  if (confirmed != true || userId == null) return;

  setState(() => isDeleting = true);

  final result = await ReviewService.deleteReview(
    productId: widget.productId,
    userId: userId!,
  );

  setState(() => isDeleting = false);

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(result['message'])),
  );

  if (result['success']) {
    Navigator.pop(context, true);
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
    child: SingleChildScrollView(  // Tambahkan ini
      child: Column(
        children: [
          const SizedBox(height: 8),
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

          const SizedBox(height: 256),

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
      ),
    );
  }
}
