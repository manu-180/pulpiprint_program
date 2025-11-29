// lib/domain/models/product.dart
import 'package:pulpiprint_program/features/products/domain/category_model.dart';

import 'product_variant.dart';

class Product {
  final int? id; // Nullable para creación
  final String title;
  final String? description;
  final double price; // Precio de Lista (Original)
  final int discount; // NUEVO: Porcentaje de descuento (0-100)
  final String imageUrl;
  final bool isFeatured;
  final int stock;
  
  // RELACIONES
  final List<Category> categories;
  final List<ProductVariant> variants;

  // Campos de envío (solo Web, si usas el mismo archivo en Admin ponlos opcionales)
  final double weightKg;
  final double heightCm;
  final double widthCm;
  final double depthCm;

  Product({
    this.id,
    required this.title,
    this.description,
    required this.price,
    this.discount = 0, // Por defecto 0
    required this.imageUrl,
    this.isFeatured = false,
    this.stock = 0,
    this.categories = const [],
    this.variants = const [],
    this.weightKg = 0.1, 
    this.heightCm = 10.0,
    this.widthCm = 10.0,
    this.depthCm = 5.0,
  });

  // --- LÓGICA DE PRECIOS INTELIGENTE ---

  // 1. Precio Final BASE (con descuento aplicado)
  double get priceWithDiscount {
    if (discount <= 0) return price;
    return price * (1 - discount / 100);
  }

  // 2. Precio Final para MOSTRAR en lista (El "Desde $...")
  // Calcula el mínimo entre las variantes (aplicando el descuento a cada una)
  double get displayPrice {
    double base = priceWithDiscount;
    
    if (variants.isNotEmpty) {
      // Aplicamos el descuento a todas las variantes para encontrar la más barata
      final minVariantPrice = variants
          .map((v) => v.price * (1 - discount / 100))
          .reduce((a, b) => a < b ? a : b);
      return minVariantPrice;
    }
    return base;
  }

  // Factory y ToJson actualizados
  factory Product.fromJson(Map<String, dynamic> json) {
    final variantsList = json['product_variants'] as List<dynamic>? ?? [];
    
    final categoriesData = json['categories'] ?? json['product_categories']; 
    List<Category> parsedCategories = [];
    if (categoriesData is List) {
       parsedCategories = categoriesData.map((e) {
         final data = e['categories'] ?? e; 
         return Category.fromJson(data);
       }).toList();
    }

    return Product(
      id: json['id'] as int?,
      title: json['titulo'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      discount: json['discount'] as int? ?? 0, // LEER DESCUENTO
      imageUrl: json['image_url'] as String? ?? '',
      isFeatured: json['is_featured'] as bool? ?? false,
      stock: json['stock'] as int? ?? 0,
      variants: variantsList.map((e) => ProductVariant.fromJson(e)).toList(),
      categories: parsedCategories,
      // Campos de envío...
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
      'discount': discount, // GUARDAR DESCUENTO
      'image_url': imageUrl,
      'is_featured': isFeatured,
      'stock': stock,
      // ... resto de campos
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'width_cm': widthCm,
      'depth_cm': depthCm,
    };
  }
  
  // CopyWith para editar
  Product copyWith({
    int? id,
    String? title,
    String? description,
    double? price,
    int? discount,
    String? imageUrl,
    bool? isFeatured,
    List<Category>? categories,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      imageUrl: imageUrl ?? this.imageUrl,
      isFeatured: isFeatured ?? this.isFeatured,
      categories: categories ?? this.categories,
      variants: variants ?? this.variants,
    );
  }
}