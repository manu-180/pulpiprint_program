// lib/features/products/presentation/providers/product_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulpiprint_program/features/products/domain/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/products_repository.dart';
import '../../domain/product_model.dart';

// 1. Provider Básico de Supabase (Acceso global al cliente)
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// 2. Provider del Repositorio (Inyección de Dependencias)
// Si mañana cambias Supabase por Firebase, solo cambias este provider.
final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ProductsRepository(client);
});

// 3. Controller Principal (AsyncNotifier)
// Gestiona la lista de productos y sus operaciones (CRUD)
final productsProvider = AsyncNotifierProvider<ProductsController, List<Product>>(ProductsController.new);

class ProductsController extends AsyncNotifier<List<Product>> {
  
  @override
  Future<List<Product>> build() async {
    // Carga inicial automática al leer el provider
    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() {
    final repository = ref.read(productsRepositoryProvider);
    return repository.getProducts();
  }

  // --- MÉTODOS DE ACCIÓN (Llamados desde la UI) ---

  // Guardar (Crear o Editar)
  Future<void> saveProduct(Product product) async {
    // 1. Ponemos estado de carga (para bloquear UI o mostrar spinner)
    state = const AsyncValue.loading();
    
    // 2. Intentamos guardar y capturamos el resultado
    // AsyncValue.guard maneja try-catch automáticamente
    state = await AsyncValue.guard(() async {
      final repository = ref.read(productsRepositoryProvider);
      await repository.saveProduct(product);
      // 3. Si tiene éxito, recargamos la lista actualizada del servidor
      return _fetchProducts();
    });
  }

  // Eliminar
  Future<void> deleteProduct(int id) async {
    // Optimistic update podría ir aquí, pero para admin panel, recarga segura es mejor
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(productsRepositoryProvider);
      await repository.deleteProduct(id);
      return _fetchProducts();
    });
  }
  
  // Refrescar manual
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchProducts());
  }
}

// ... al final de product_providers.dart

// Provider para obtener la lista maestra de categorías
final categoriesProvider = StreamProvider<List<Category>>((ref) {
  final repository = ref.watch(productsRepositoryProvider);
  return repository.getCategoriesStream();
});