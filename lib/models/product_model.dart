import '../models/product_image.dart';
import '../utils/parsing_utils.dart';

class Product {
  final int id;
  final String nama;
  final String deskripsi;
  final double harga;
  final int stokId;
  final String status;
  final double rating;
  final int sellerId;
  final int categoryId;
  final String createdAt;
  List<ProductImage>? images;

  Product({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.stokId,
    required this.status,
    required this.rating,
    required this.sellerId,
    required this.categoryId,
    required this.createdAt,
    this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
  return Product(
    id: parseInt(json['id']),
    nama: json['nama'] ?? '',
    deskripsi: json['deskripsi'] ?? '',
    harga: parseDouble(json['harga']),
    stokId: parseInt(json['stok_id']),
    status: json['status'] ?? 'available',
    rating: parseDouble(json['rating']),
    sellerId: parseInt(json['seller_id']),
    categoryId: parseInt(json['category_id']),
    createdAt: json['created_at'] ?? '',
    images: json['images'] != null
        ? (json['images'] as List)
            .map((img) => ProductImage.fromJson(img))
            .toList()
        : [],
  );
}

}
