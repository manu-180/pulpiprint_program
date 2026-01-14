// lib/features/products/domain/category_model.dart

class Category {
  final int id;
  final String name;
  final int? parentId; // Nuevo: Soporte para subcategorías

  Category({
    required this.id, 
    required this.name,
    this.parentId,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      parentId: json['parent_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id, 
    'name': name,
    'parent_id': parentId,
  };
  
  @override
  bool operator ==(Object other) => other is Category && other.id == id;
  @override
  int get hashCode => id.hashCode;
}