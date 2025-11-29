// lib/features/products/presentation/widgets/product_list_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/product_model.dart';

class ProductListItem extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'es_AR', symbol: '\$');

    // --- LÓGICA DE PRECIOS ---
    final bool hasDiscount = product.discount > 0;
    
    // 1. Calcular precio original (Sin descuento)
    double originalBasePrice = product.price;
    if (product.variants.isNotEmpty) {
      // Si hay variantes, buscamos la más barata original
      originalBasePrice = product.variants.map((v) => v.price).reduce((a, b) => a < b ? a : b);
    }

    // 2. Textos para mostrar
    final String originalPriceText = product.variants.isNotEmpty
        ? "Desde ${currencyFormatter.format(originalBasePrice)}"
        : currencyFormatter.format(originalBasePrice);

    final String finalPriceText = product.variants.isNotEmpty
        ? "Desde ${currencyFormatter.format(product.displayPrice)}" // displayPrice ya trae el descuento del modelo
        : currencyFormatter.format(product.priceWithDiscount);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // 1. IMAGEN
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    image: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (product.imageUrl == null || product.imageUrl!.isEmpty)
                      ? Icon(LucideIcons.image, size: 20, color: Colors.grey.shade400)
                      : null,
                ),

                const SizedBox(width: 16),

                // 2. INFO PRINCIPAL (Título y Precios)
                SizedBox(
                  width: 240, // Un poco más ancho para que entren los precios
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              product.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (product.isFeatured) ...[
                            const SizedBox(width: 8),
                            Icon(LucideIcons.star, size: 14, color: Colors.amber.shade400),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // --- VISUALIZACIÓN DE PRECIOS ---
                      if (hasDiscount) ...[
                        // Precio Viejo Tachado
                        Text(
                          originalPriceText,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        // Precio Nuevo + Badge
                        Row(
                          children: [
                            Text(
                              finalPriceText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface, // Color oferta
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Text(
                                '-${product.discount}%',
                                style: const TextStyle(
                                  fontSize: 10, 
                                  color: Colors.green, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            )
                          ],
                        )
                      ] else ...[
                        // Precio Normal
                        Text(
                          finalPriceText,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // 3. CATEGORÍAS (Expanded para que se adapte)
                Expanded(
                  child: product.categories.isEmpty 
                  ? const SizedBox()
                  : Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 4,
                        clipBehavior: Clip.hardEdge,
                        children: product.categories.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                            ),
                            child: Text(
                              cat.name,
                              style: TextStyle(
                                fontSize: 10, 
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                                fontWeight: FontWeight.w500
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ),

                const SizedBox(width: 12),

                // 4. ACCIONES
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.pencil, size: 18),
                      color: Colors.grey.shade500,
                      onPressed: onEdit,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      tooltip: 'Editar',
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, size: 18),
                      color: Colors.red.shade300,
                      onPressed: onDelete,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}