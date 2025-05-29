import 'dart:typed_data';

class ProductItem {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final Uint8List? image;
  final String imageBase64;
  final int weight; // Berat produk dalam gram

  ProductItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.image,
    required this.imageBase64,
    required this.weight,
  });
}