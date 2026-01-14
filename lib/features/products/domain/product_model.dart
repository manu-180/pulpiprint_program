// lib/features/products/domain/product_model.dart

import 'category_model.dart';
import 'product_variant.dart';

class Product {
  final int? id;
  final String title;
  final String? description;
  final double price; 
  final int discount; 
  final List<String> images; 
  final bool isFeatured;
  final int stock;
  final int? sortOrder;
  
  final List<Category> categories;
  final List<ProductVariant> variants;

  final double weightKg; 
  final double heightCm;
  final double widthCm;
  final double depthCm;

  Product({
    this.id,
    required this.title,
    this.description,
    required this.price,
    this.discount = 0,
    required this.images,
    this.isFeatured = false,
    this.stock = 0,
    this.sortOrder,
    this.categories = const [],
    this.variants = const [],
    this.weightKg = 0.1, 
    this.heightCm = 10.0,
    this.widthCm = 10.0,
    this.depthCm = 5.0,
  });

  String get imageUrl => images.isNotEmpty ? images.first : '';

  double get priceWithDiscount {
    if (discount <= 0) return price;
    return price * (1 - discount / 100);
  }

  double get displayPrice {
    if (variants.isNotEmpty) {
      return variants
          .map((v) => v.price * (1 - discount / 100))
          .reduce((a, b) => a < b ? a : b);
    }
    return priceWithDiscount;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      title: json['titulo'] as String? ?? '', 
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discount: json['discount'] as int? ?? 0, 
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      isFeatured: json['is_featured'] as bool? ?? false,
      stock: json['stock'] as int? ?? 0,
      sortOrder: json['sort_order'] as int?, 
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.1,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 10.0,
      widthCm: (json['width_cm'] as num?)?.toDouble() ?? 10.0,
      depthCm: (json['depth_cm'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'titulo': title,
      'description': description,
      'price': price,
      'discount': discount,
      'images': images,     
      'is_featured': isFeatured,
      'stock': stock,
      'sort_order': sortOrder,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'width_cm': widthCm,
      'depth_cm': depthCm,
    };
  }
}