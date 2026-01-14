// lib/features/products/data/products_repository.dart

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';
import '../domain/category_model.dart';
import '../domain/product_variant.dart';

class ProductsRepository {
  final SupabaseClient _client;
  ProductsRepository(this._client);

  Future<List<Product>> getProducts() async {
    try {
      final response = await _client
          .from('products_pulpiprint')
          .select('''
            *,
            product_variants (*),
            product_categories (
              categories (*)
            )
          ''')
          .order('sort_order', ascending: true);

      return (response as List).map((json) {
        // Mapeo manual de categorías anidadas si es necesario
        final List<Category> cats = [];
        if (json['product_categories'] != null) {
          for (var item in json['product_categories']) {
            if (item['categories'] != null) {
              cats.add(Category.fromJson(item['categories']));
            }
          }
        }

        return Product.fromJson({
          ...json,
          'categories': cats,
          'variants': json['product_variants'] ?? [],
        });
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar productos: $e');
    }
  }

  Future<void> saveProduct(Product product) async {
    try {
      // 1. Upsert del producto principal
      // El método toJson() ya incluye la lista 'images' y excluye 'image_url'
      final productData = await _client
          .from('products_pulpiprint')
          .upsert(product.toJson())
          .select()
          .single();

      final int productId = productData['id'];

      // 2. Limpieza de relaciones existentes si es una edición
      if (product.id != null) {
        await _client.from('product_variants').delete().eq('product_id', productId);
        await _client.from('product_categories').delete().eq('product_id', productId);
      }

      // 3. Inserción de nuevas variantes
      if (product.variants.isNotEmpty) {
        await _client.from('product_variants').insert(
          product.variants.map((v) => {
            'product_id': productId,
            'size_label': v.sizeLabel,
            'price': v.price,
          }).toList()
        );
      }

      // 4. Inserción de nuevas categorías
      if (product.categories.isNotEmpty) {
        await _client.from('product_categories').insert(
          product.categories.map((c) => {
            'product_id': productId,
            'category_id': c.id,
          }).toList()
        );
      }
    } catch (e) {
      throw Exception('Error al guardar en el repositorio: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      await _client.from('products_pulpiprint').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar producto: $e');
    }
  }

  Future<void> updateSortOrder(List<Product> products) async {
    try {
      final updates = products.asMap().entries.map((entry) {
        return _client.from('products_pulpiprint')
            .update({'sort_order': entry.key})
            .eq('id', entry.value.id!);
      }).toList();
      await Future.wait(updates);
    } catch (e) {
      throw Exception('Error al actualizar el orden: $e');
    }
  }

  Future<String> uploadImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.${fileExt}';
      final filePath = 'uploads/$fileName';

      await _client.storage.from('product_images').uploadBinary(
        filePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      final String publicUrl = _client.storage
          .from('product_images')
          .getPublicUrl(filePath);
          
      return publicUrl;
    } catch (e) {
      throw Exception('Error en Storage de Supabase: $e');
    }
  }

  Stream<List<Category>> getCategoriesStream() {
    return _client
        .from('categories')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Category.fromJson(json)).toList());
  }

  Future<void> createCategory(String name, {int? parentId}) async {
    await _client.from('categories').insert({'name': name, 'parent_id': parentId});
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }
}