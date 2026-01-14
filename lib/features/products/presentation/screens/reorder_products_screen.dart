// lib/features/products/presentation/screens/reorder_products_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../domain/product_model.dart';
import '../providers/product_providers.dart';

class ReorderProductsScreen extends ConsumerStatefulWidget {
  const ReorderProductsScreen({super.key});

  @override
  ConsumerState<ReorderProductsScreen> createState() => _ReorderProductsScreenState();
}

class _ReorderProductsScreenState extends ConsumerState<ReorderProductsScreen> {
  List<Product> _localProducts = [];
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final products = ref.read(productsProvider).value ?? [];
      setState(() {
        _localProducts = List.from(products);
      });
    });
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(productsRepositoryProvider).updateSortOrder(_localProducts);
      // Forzamos la recarga del provider para ver los cambios reflejados en la lista principal
      ref.invalidate(productsProvider); 
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden del catálogo actualizado correctamente'), 
            backgroundColor: Colors.green
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizar Catálogo'),
        actions: [
          if (_hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _saveOrder,
                icon: _isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(LucideIcons.save),
                label: const Text('Guardar Orden'),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.primaryContainer.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(LucideIcons.mousePointer2, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Haz clic y arrastra inmediatamente para reordenar.', 
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _localProducts.isEmpty 
              ? const Center(child: CircularProgressIndicator())
              : ReorderableGridView.builder(
                  padding: const EdgeInsets.all(24),
                  
                  // --- CLAVE 1: DELAY CERO PARA ESCRITORIO ---
                  // Esto elimina la necesidad de "mantener presionado". 
                  // El arrastre comienza en cuanto se mueve el mouse con el click apretado.
                  dragStartDelay: Duration.zero,
                  
                  // --- CLAVE 2: PHYSICS ---
                  // Asegura que el scroll funcione bien junto con el drag.
                  physics: const AlwaysScrollableScrollPhysics(),

                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  
                  itemCount: _localProducts.length,
                  
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      final item = _localProducts.removeAt(oldIndex);
                      _localProducts.insert(newIndex, item);
                      _hasChanges = true;
                    });
                  },
                  
                  itemBuilder: (context, index) {
                    final product = _localProducts[index];
                    
                    // --- CLAVE 3: WIDGET LIMPIO ---
                    // Eliminamos InkWells, GestureDetectors o Listeners extras.
                    // Usamos un Card simple que no "roba" los eventos del mouse.
                    return Card(
                      key: ValueKey(product.id), // Key única indispensable
                      margin: EdgeInsets.zero,
                      elevation: 3,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200)
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: product.images.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl, 
                                      fit: BoxFit.cover,
                                      // IMPORTANTE: Evita que la imagen capture eventos semánticos innecesarios
                                      excludeFromSemantics: true, 
                                    )
                                  : Container(
                                      color: Colors.grey.shade100, 
                                      child: const Icon(LucideIcons.image, color: Colors.grey)
                                    ),
                              ),
                              Container(
                                color: theme.cardColor,
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  product.title, 
                                  maxLines: 2, 
                                  overflow: TextOverflow.ellipsis, 
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)
                                ),
                              ),
                            ],
                          ),
                          // Badge de número para referencia visual
                          Positioned(
                            top: 8, 
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(blurRadius: 2, color: Colors.black26)]
                              ),
                              child: Text(
                                '${index + 1}', 
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
                              ),
                            ),
                          ),
                          // Icono explícito de "Drag" para dar feedback visual al usuario
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(4)
                              ),
                              child: const Icon(LucideIcons.move, color: Colors.white, size: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}