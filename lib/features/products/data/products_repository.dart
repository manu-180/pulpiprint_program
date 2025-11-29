// lib/features/products/data/products_repository.dart

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';
import '../domain/category_model.dart';
import '../domain/product_variant.dart';

class ProductsRepository {
  final SupabaseClient _client;

  ProductsRepository(this._client);

  // 1. Obtener Productos con TODAS sus relaciones (Join)
  Future<List<Product>> getProducts() async {
    try {
      // SINTAXIS AVANZADA DE SUPABASE:
      // *, 
      // product_variants(*), 
      // product_categories(categories(*)) -> Esto navega la tabla intermedia y trae la categoría real
      final List<dynamic> response = await _client
          .from('products_pulpiprint')
          .select('*, product_variants(*), product_categories(categories(*))')
          .order('id', ascending: false);

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar productos complejos: $e');
    }
  }

  // 2. Obtener lista de categorías disponibles (Para el Dropdown del formulario)
  Future<List<Category>> getAllCategories() async {
    try {
      final response = await _client.from('categories').select().order('name');
      return (response as List).map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar categorías: $e');
    }
  }

  // 3. Guardado Complejo (Transaccional)
  Future<void> saveProduct(Product product) async {
    try {
      // A. Guardar/Actualizar el Producto Base
      final productData = await _client
          .from('products_pulpiprint')
          .upsert(product.toJson())
          .select()
          .single(); // Obtenemos el registro creado para saber su ID

      final int productId = productData['id'];

      // B. Gestionar Variantes (Estrategia: Borrar viejas e insertar nuevas para evitar inconsistencias)
      // Solo si es una actualización (si el producto ya tenía ID) limpiamos lo anterior
      if (product.id != null) {
        await _client.from('product_variants').delete().eq('product_id', productId);
        await _client.from('product_categories').delete().eq('product_id', productId);
      }

      // C. Insertar Nuevas Variantes
      if (product.variants.isNotEmpty) {
        final variantsToInsert = product.variants.map((v) {
          return {
            'product_id': productId,
            'size_label': v.sizeLabel,
            'price': v.price,
          };
        }).toList();
        await _client.from('product_variants').insert(variantsToInsert);
      }

      // D. Insertar Nuevas Relaciones de Categoría
      if (product.categories.isNotEmpty) {
        final categoriesToInsert = product.categories.map((c) {
          return {
            'product_id': productId,
            'category_id': c.id,
          };
        }).toList();
        await _client.from('product_categories').insert(categoriesToInsert);
      }

    } catch (e) {
      // En un entorno real, aquí deberíamos revertir cambios si falla un paso intermedio
      throw Exception('Error crítico al guardar producto y sus relaciones: $e');
    }
  }

  // 4. Eliminar
  Future<void> deleteProduct(int id) async {
    // Gracias al "ON DELETE CASCADE" que pusimos en SQL, 
    // al borrar el producto se borran solas las variantes y referencias de categoría.
    await _client.from('products_pulpiprint').delete().eq('id', id);
  }

  // 5. Crear Categoría
  Future<void> createCategory(String name) async {
    try {
      await _client.from('categories').insert({'name': name});
    } catch (e) {
      throw Exception('Error al crear categoría: $e');
    }
  }

  // 6. Eliminar Categoría
  Future<void> deleteCategory(int id) async {
    try {
      await _client.from('categories').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error al eliminar categoría: $e');
    }
  }
  // 7. Subir Imagen
Future<String> uploadImage(XFile imageFile) async {
  try {
    final bytes = await imageFile.readAsBytes();
    final fileExt = imageFile.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final filePath = 'uploads/$fileName'; // Carpeta uploads dentro del bucket

    // Subir al bucket 'products'
 await _client.storage.from('product_images').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg'),

    
    );

    // Obtener URL Pública
    final imageUrl = _client.storage.from('product_images').getPublicUrl(filePath);
    return imageUrl;
  } catch (e) {
    throw Exception('Error al subir imagen: $e');
  }
}

Stream<List<Category>> getCategoriesStream() {
    return _client
        .from('categories')
        .stream(primaryKey: ['id']) // Escucha cambios basados en ID
        .order('name') // Las mantiene ordenadas alfabéticamente
        .map((data) => data.map((json) => Category.fromJson(json)).toList());
  }
}
  
