class Category {
  final int id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
  
  // Para comparaciones (dropdowns)
  @override
  bool operator ==(Object other) => other is Category && other.id == id;
  @override
  int get hashCode => id.hashCode;
}