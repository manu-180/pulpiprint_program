// lib/widgets/categories_nav_bar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:pulpiprint_program/features/products/domain/category_model.dart';
// IMPORTANTE: Asegúrate de importar el archivo donde están definidos los providers
import 'package:pulpiprint_program/features/products/presentation/providers/product_providers.dart';

class CategoriesNavBar extends ConsumerStatefulWidget {
  const CategoriesNavBar({super.key});

  @override
  ConsumerState<CategoriesNavBar> createState() => _CategoriesNavBarState();
}

class _CategoriesNavBarState extends ConsumerState<CategoriesNavBar> {
  Category? _hoveredParent;
  Category? _activeParent;

  @override
  Widget build(BuildContext context) {
    // CORRECCIÓN: Usamos 'categoriesProvider' que es el nombre definido en product_providers.dart
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return categoriesAsync.when(
      data: (allCats) {
        // Filtrar categorías principales (aquellas que no tienen un parentId)
        final parents = allCats.where((c) => c.parentId == null).toList();
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BARRA PRINCIPAL
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(bottom: BorderSide(color: theme.dividerColor, width: 0.5)),
              ),
              child: Center(
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: parents.length,
                  itemBuilder: (context, index) {
                    final cat = parents[index];
                    final isActive = _activeParent == cat;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredParent = cat),
                      child: InkWell(
                        onTap: () => setState(() => _activeParent = isActive ? null : cat),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: isActive ? theme.colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                          ),
                          child: Text(
                            cat.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive ? theme.colorScheme.primary : theme.hintColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // SEGUNDA BARRA (SUBCATEGORÍAS)
            if (_activeParent != null)
              FadeInDown(
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: double.infinity,
                  height: 45,
                  color: theme.colorScheme.surface.withOpacity(0.95),
                  child: _buildSubBar(allCats, _activeParent!),
                ),
              ),
          ],
        );
      },
      loading: () => const SizedBox(height: 50, child: LinearProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildSubBar(List<Category> all, Category parent) {
    // Filtrar subcategorías cuyo parentId coincida con el ID de la categoría padre seleccionada
    final subs = all.where((c) => c.parentId == parent.id).toList();
    if (subs.isEmpty) return const SizedBox();

    return Center(
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: subs.length,
        itemBuilder: (context, index) {
          final sub = subs[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextButton(
              onPressed: () {
                // Aquí puedes disparar la lógica de filtrado de productos
              },
              child: Text(
                sub.name,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
              ),
            ),
          );
        },
      ),
    );
  }
}