class ProductVariant {
  final int? id;
  final int? productId; // Nullable al crear
  final String sizeLabel;
  final double price;

  ProductVariant({
    this.id,
    this.productId,
    required this.sizeLabel,
    required this.price,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as int?,
      productId: json['product_id'] as int?,
      sizeLabel: json['size_label'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      'size_label': sizeLabel,
      'price': price,
    };
  }
}