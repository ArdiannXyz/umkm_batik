import '../utils/parsing_utils.dart';

class ProductImage {
  final int id;
  final int productId;
  final String base64Image;
  final bool isMain;

  ProductImage({
    required this.id,
    required this.productId,
    required this.base64Image,
    required this.isMain,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: parseInt(json['id']),
      productId: parseInt(json['product_id']),
      base64Image: json['image_base64'] ?? json['image_product'] ?? '', // aman fallback
      isMain: json['is_main'].toString() == '1' || json['is_main'] == true,
    );
  }
}
