// lib/features/products/presentation/widgets/category_management_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/product_providers.dart';
import '../../domain/category_model.dart';

class CategoryManagementDialog extends ConsumerStatefulWidget {
  const CategoryManagementDialog({super.key});

  @override
  ConsumerState<CategoryManagementDialog> createState() => _CategoryManagementDialogState();
}

class _CategoryManagementDialogState extends ConsumerState<CategoryManagementDialog> {
  final _categoryController = TextEditingController();
  Category? _selectedParent;

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    if (_categoryController.text.isEmpty) return;
    
    try {
      await ref.read(productsRepositoryProvider).createCategory(
        _categoryController.text.trim(),
        parentId: _selectedParent?.id,
      );
      _categoryController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Categoría añadida'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleDelete(int id) async {
    try {
      await ref.read(productsRepositoryProvider).deleteCategory(id);
      if (_selectedParent?.id == id) {
        setState(() => _selectedParent = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Gestionar Estructura de Catálogo', 
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
              ],
            ),
            const SizedBox(height: 24),
            
            // --- CAMPO DE ENTRADA ---
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: _selectedParent == null 
                        ? 'Nombre de nueva categoría principal...' 
                        : 'Nueva subcategoría para "${_selectedParent!.name}"...',
                      prefixIcon: Icon(_selectedParent == null ? LucideIcons.folderPlus : LucideIcons.gitBranch),
                    ),
                    onFieldSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _addCategory,
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Agregar'),
                ),
              ],
            ),
            
            if (_selectedParent != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton.icon(
                  onPressed: () => setState(() => _selectedParent = null),
                  icon: const Icon(LucideIcons.arrowLeft, size: 14),
                  label: const Text('Volver a crear categorías principales'),
                ),
              ),

            const Divider(height: 40),

            // --- LISTADO ---
            Expanded(
              child: categoriesAsync.when(
                data: (all) {
                  final parents = all.where((c) => c.parentId == null).toList();
                  
                  return Row(
                    children: [
                      // Panel Izquierdo: Principales
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CATEGORÍAS PRINCIPALES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: parents.length,
                                itemBuilder: (context, index) {
                                  final cat = parents[index];
                                  final isSelected = _selectedParent?.id == cat.id;
                                  return ListTile(
                                    selected: isSelected,
                                    dense: true,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    title: Text(cat.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                                    onTap: () => setState(() => _selectedParent = cat),
                                    // BOTÓN ELIMINAR CATEGORÍA PRINCIPAL
                                    trailing: IconButton(
                                      icon: const Icon(LucideIcons.trash2, size: 16),
                                      color: Colors.red.withOpacity(0.7),
                                      onPressed: () => _confirmDelete(cat.id, cat.name),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const VerticalDivider(width: 40),
                      // Panel Derecho: Subcategorías
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedParent == null ? 'SELECCIONA UNA CATEGORÍA' : 'SUBCATEGORÍAS DE ${_selectedParent!.name.toUpperCase()}', 
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _selectedParent == null 
                                ? const Center(child: Icon(LucideIcons.layers, size: 48, color: Colors.black12))
                                : ListView(
                                    children: all.where((c) => c.parentId == _selectedParent!.id).map((sub) => ListTile(
                                      title: Text(sub.name),
                                      dense: true,
                                      trailing: IconButton(
                                        icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
                                        onPressed: () => _confirmDelete(sub.id, sub.name),
                                      ),
                                    )).toList(),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, __) => Text('Error: $e'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar categoría?'),
        content: Text('Estás por eliminar "$name". Esta acción desvinculará los productos asociados y eliminará sus subcategorías si es una principal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete(id);
            }, 
            child: const Text('Eliminar')
          ),
        ],
      ),
    );
  }
}