// lib/features/products/presentation/screens/products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:pulpiprint_program/features/products/presentation/providers/auth_provider.dart';
import '../providers/product_providers.dart';
import '../widgets/product_list_item.dart';
import '../../../../core/providers/theme_provider.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  // Función para mostrar diálogo de confirmación antes de borrar
  void _confirmDelete(BuildContext context, WidgetRef ref, int productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar producto?'),
        content: const Text('Esta acción no se puede deshacer y borrará todas las variantes asociadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx); 
              ref.read(productsProvider.notifier).deleteProduct(productId);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Navegación al formulario
  void _openProductForm(BuildContext context, {int? productId}) {
    if (productId != null) {
      context.go('/product/$productId');
    } else {
      context.go('/product/new');
    }
  }

  // NUEVO: Función de Logout
  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Diálogo de confirmación profesional
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 1. Llamamos al método de logout de Supabase
      await ref.read(loginControllerProvider.notifier).logout();
      
      // 2. Redirigimos al Login manualmente
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(productsProvider);
    final isDarkMode = ref.watch(isDarkModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario PulpiPrint', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // 1. CAMBIAR TEMA
          IconButton(
            icon: Icon(isDarkMode ? LucideIcons.sun : LucideIcons.moon),
            onPressed: () {
              ref.read(isDarkModeProvider.notifier).update((state) => !state);
            },
            tooltip: 'Cambiar Tema',
          ),
          
          const SizedBox(width: 4),

          // 2. REFRESCAR
          IconButton(
            icon: const Icon(LucideIcons.refreshCcw),
            onPressed: () => ref.read(productsProvider.notifier).refresh(),
            tooltip: 'Recargar lista',
          ),

          const SizedBox(width: 4),
          
          // 3. LOGOUT (NUEVO)
          // Usamos un color rojo suave o gris para diferenciarlo
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            color: Colors.red.shade300, 
            onPressed: () => _logout(context, ref),
            tooltip: 'Cerrar Sesión',
          ),
          
          const SizedBox(width: 16),
        ],
      ),
      body: productsState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.read(productsProvider.notifier).refresh(),
                icon: const Icon(LucideIcons.refreshCcw),
                label: const Text('Reintentar'),
              )
            ],
          ),
        ),
        data: (products) {
          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.box, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No hay productos aún',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // LISTA DE RENGLONES
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductListItem(
                product: product,
                onEdit: () => _openProductForm(context, productId: product.id),
                onDelete: () => _confirmDelete(context, ref, product.id!),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProductForm(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('Nuevo Producto'),
      ),
    );
  }
}