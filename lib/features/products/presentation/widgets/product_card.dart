// lib/features/products/presentation/widgets/product_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final currencyFormatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');
    final priceLabel = product.variants.isNotEmpty
        ? "Desde ${currencyFormatter.format(product.displayPrice)}"
        : currencyFormatter.format(product.price);

    return Card(
      elevation: 4, 
      shadowColor: Colors.black.withOpacity(0.5), // Sombra negra fuerte
      
      // Color de superficie: Gris oscuro (#1E1E1E) vs Blanco
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      surfaceTintColor: Colors.transparent, // Importante para que no se tiña de morado
      
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // Borde sutil en oscuro para separar del fondo negro
        side: BorderSide(
          color: isDark ? Colors.white10 : Colors.transparent, 
          width: 1
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- IMAGEN ---
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(LucideIcons.image, size: 40, color: Colors.grey),
                        )
                      : const Icon(LucideIcons.image, size: 40, color: Colors.grey),
                ),
                // Badge de Destacado sobre la imagen (Más moderno)
                if (product.isFeatured)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade400,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.star, size: 10, color: Colors.black87),
                          SizedBox(width: 4),
                          Text(
                            'TOP',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- DETALLES ---
          Padding(
            padding: const EdgeInsets.all(16.0), // Más padding interno
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                Text(
                  priceLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                
                if (product.categories.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 24, // Altura fija para la fila de chips
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: product.categories.length,
                      separatorBuilder: (_,__) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final cat = product.categories[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                          ),
                          child: Center(
                            child: Text(
                              cat.name,
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // --- ACCIONES ---
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.grey.shade200),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.pencil, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text('Editar', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: isDark ? Colors.white10 : Colors.grey.shade300),
              Expanded(
                child: InkWell(
                  onTap: onDelete,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.trash2, size: 16, color: Colors.red.shade400),
                        const SizedBox(width: 8),
                        Text('Borrar', style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}