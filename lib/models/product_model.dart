class Product {
  final int id;
  final String nama;
  final String deskripsi;
  final double harga;
  final int stokId;
  final String status;
  final double rating;
  final int berat;
  final String createdAt;
  final int? quantity; // dari join dengan stocks table
  final ProductImage? mainImage;
  final List<ProductImage> images;
  final String? thumbnailUrl;
  final String? mainImageBase64;

  Product({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.harga,
    required this.stokId,
    required this.status,
    required this.rating,
    required this.berat,
    required this.createdAt,
    this.quantity,
    this.mainImage,
    this.images = const [],
    this.thumbnailUrl,
    this.mainImageBase64,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      nama: json['nama'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      harga: (json['harga'] ?? 0).toDouble(),
      stokId: json['stok_id'] ?? 0,
      status: json['status'] ?? 'available',
      rating: (json['rating'] ?? 0.0).toDouble(),
      berat: json['berat'] ?? 0,
      createdAt: json['created_at'] ?? '',
      quantity: json['quantity'],
      mainImage: json['main_image'] != null 
          ? ProductImage.fromJson(json['main_image']) 
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((item) => ProductImage.fromJson(item))
              .toList()
          : [],
      thumbnailUrl: json['thumbnail_url'],
      mainImageBase64: json['main_image_base64'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'deskripsi': deskripsi,
      'harga': harga,
      'stok_id': stokId,
      'status': status,
      'rating': rating,
      'berat': berat,
      'created_at': createdAt,
      'quantity': quantity,
      'main_image': mainImage?.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      'thumbnail_url': thumbnailUrl,
      'main_image_base64': mainImageBase64,
    };
  }
}

class ProductImage {
  final int id;
  final int productId;
  final int isMain;
  final String imageProduct; // base64 string
  final String? imageUrl;
  final String? imageBase64; // full data URL format

  ProductImage({
    required this.id,
    required this.productId,
    required this.isMain,
    required this.imageProduct,
    this.imageUrl,
    this.imageBase64,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      productId: json['product_id'] ?? 0,
      isMain: json['is_main'] ?? 0,
      imageProduct: json['image_product'] ?? '',
      imageUrl: json['image_url'],
      imageBase64: json['image_base64'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'is_main': isMain,
      'image_product': imageProduct,
      'image_url': imageUrl,
      'image_base64': imageBase64,
    };
  }
}