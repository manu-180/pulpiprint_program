// lib/features/products/presentation/screens/product_form_screen.dart

import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../domain/product_model.dart';
import '../../domain/category_model.dart';
import '../../domain/product_variant.dart';
import '../providers/product_providers.dart';
import '../widgets/product_image_picker.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  final int? productId;

  const ProductFormScreen({super.key, this.productId});

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _descController = TextEditingController(); 
  final _priceController = TextEditingController();
  final _discountController = TextEditingController(text: '0'); // Nuevo controlador
  final _imageController = TextEditingController();
  bool _isFeatured = false;

  List<Category> _selectedCategories = [];
  final List<Map<String, TextEditingController>> _variantControllers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      _loadProductData();
    }
  }

  void _loadProductData() async {
    final products = ref.read(productsProvider).valueOrNull ?? [];
    try {
      final product = products.firstWhere((p) => p.id == widget.productId);
      
      _titleController.text = product.title;
      
      // CORRECCIÓN 1: Manejar nulo en descripción
      _descController.text = product.description ?? ''; 
      
      _priceController.text = product.price.toString();
      _discountController.text = product.discount.toString(); // Cargar descuento
      
      // CORRECCIÓN 2: ImageUrl ya no es nulo en el modelo
      _imageController.text = product.imageUrl; 
      
      _isFeatured = product.isFeatured;
      
      setState(() {
        _selectedCategories = List.from(product.categories);
        for (var v in product.variants) {
          _variantControllers.add({
            'size': TextEditingController(text: v.sizeLabel),
            'price': TextEditingController(text: v.price.toString()),
          });
        }
      });
    } catch (e) {
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _imageController.dispose();
    for (var row in _variantControllers) {
      row['size']?.dispose();
      row['price']?.dispose();
    }
    super.dispose();
  }

  // --- MÉTODOS DE VARIANTES ---
  void _addVariant() {
    setState(() {
      _variantControllers.add({
        'size': TextEditingController(),
        'price': TextEditingController(),
      });
    });
  }

  void _removeVariant(int index) {
    setState(() {
      final removed = _variantControllers.removeAt(index);
      removed['size']?.dispose();
      removed['price']?.dispose();
    });
  }

  // --- MÉTODOS DE CATEGORÍA ---
  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    
    void _submit() {
      if (controller.text.isNotEmpty) {
        ref.read(productsRepositoryProvider).createCategory(controller.text.trim());
        Navigator.pop(context);
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva Categoría'),
        content: TextField(
          controller: controller, 
          autofocus: true, 
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: _submit,
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Borrar "${category.name}" para siempre?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            icon: const Icon(LucideIcons.trash2, size: 18),
            label: const Text('Eliminar'),
            onPressed: () {
              ref.read(productsRepositoryProvider).deleteCategory(category.id);
              setState(() => _selectedCategories.removeWhere((c) => c.id == category.id));
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  // --- GUARDAR INTELIGENTE ---
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos una categoría'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final variants = _variantControllers.map((row) {
        return ProductVariant(
          sizeLabel: row['size']!.text,
          price: double.tryParse(row['price']!.text) ?? 0.0,
        );
      }).toList();

      double finalBasePrice;
      if (variants.isNotEmpty) {
        finalBasePrice = variants.map((v) => v.price).reduce(min);
      } else {
        finalBasePrice = double.tryParse(_priceController.text) ?? 0.0;
      }

      final newProduct = Product(
        id: widget.productId,
        title: _titleController.text,
        description: _descController.text,
        price: finalBasePrice,
        discount: int.tryParse(_discountController.text) ?? 0, // Guardar descuento
        imageUrl: _imageController.text,
        isFeatured: _isFeatured,
        categories: _selectedCategories,
        variants: variants,
      );

      await ref.read(productsProvider.notifier).saveProduct(newProduct);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto guardado'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final hasVariants = _variantControllers.isNotEmpty;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Nuevo Producto' : 'Editar Producto'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Icon(LucideIcons.save),
              label: const Text('Guardar'),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGEN ---
              ProductImagePicker(urlController: _imageController),
              const SizedBox(height: 24),

              // --- DATOS PRINCIPALES ---
              Text('Información General', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Nombre del Producto', hintText: 'Ej: Llavero Pulpi'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Descripción', 
                  hintText: 'Detalles del material, tamaño aproximado, etc.',
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),

              // --- FILA PRECIO Y DESCUENTO ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AnimatedCrossFade(
                  firstChild: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Único', 
                            prefixText: '\$ ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (!hasVariants && (v == null || v.isEmpty)) return 'Requerido';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      // CAMPO DESCUENTO
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _discountController,
                          decoration: const InputDecoration(
                            labelText: 'Descuento',
                            suffixText: '%',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: Container(
                          decoration: BoxDecoration(
                             color: isDark ? const Color(0xFF252525) : Colors.white,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                          ),
                          child: SwitchListTile(
                            title: const Text('Destacado'),
                            value: _isFeatured,
                            onChanged: (v) => setState(() => _isFeatured = v),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // ESTADO CUANDO HAY VARIANTES (Solo Descuento y Switch)
                  secondChild: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _discountController,
                          decoration: const InputDecoration(
                            labelText: 'Descuento General',
                            suffixText: '%',
                            helperText: 'Aplica a todos los talles',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                             color: isDark ? const Color(0xFF252525) : Colors.white,
                             borderRadius: BorderRadius.circular(12),
                             border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                          ),
                          child: SwitchListTile(
                            title: const Text('Destacado'),
                            subtitle: const Text('Precio auto-calculado por talles.'),
                            value: _isFeatured,
                            onChanged: (v) => setState(() => _isFeatured = v),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  crossFadeState: !hasVariants ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 300),
                ),
              ),

              const Divider(height: 48),

              // --- CATEGORÍAS ---
              Text('Categorías', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              const SizedBox(height: 8),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutQuart,
                child: categoriesAsync.when(
                  data: (allCategories) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Wrap(
                      key: ValueKey(allCategories.length),
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...allCategories.map((cat) {
                          final isSelected = _selectedCategories.contains(cat);
                          return GestureDetector(
                            onLongPress: () => _showDeleteCategoryDialog(cat),
                            child: FilterChip(
                              label: Text(cat.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selected 
                                    ? _selectedCategories.add(cat) 
                                    : _selectedCategories.remove(cat);
                                });
                              },
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          );
                        }),
                        
                        // BOTÓN CREAR (Color corregido)
                        ActionChip(
                          onPressed: _showAddCategoryDialog,
                          avatar: Icon(LucideIcons.plus, size: 16, color: colorScheme.onPrimary),
                          label: const Text('Crear'),
                          backgroundColor: colorScheme.primary,
                          labelStyle: TextStyle(color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(
                    height: 50, 
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2))
                  ),
                  error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                ),
              ),

              const Divider(height: 48),

              // --- VARIANTES ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Variantes / Talles', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  FilledButton.tonalIcon(
                    onPressed: _addVariant,
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Agregar Talle'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (_variantControllers.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.transparent : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Text(
                      'Producto simple. Se usará el "Precio Único". Agrega talles si el precio varía.',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _variantControllers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final row = _variantControllers[index];
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252525) : Colors.white,
                        border: Border.all(color: isDark ? Colors.transparent : Colors.grey.withOpacity(0.2)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            // Recorte izquierdo
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                              child: TextFormField(
                                controller: row['size'],
                                decoration: const InputDecoration(labelText: 'Etiqueta', hintText: 'Ej: XL', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8), filled: true),
                              ),
                            ),
                          ),
                          Container(width: 1, height: 24, color: Colors.grey.shade300),
                          Expanded(
                            // Recorte derecho
                            child: ClipRRect(
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                              child: TextFormField(
                                controller: row['price'],
                                decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ ', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 8), filled: true),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.xCircle, color: Colors.red),
                            onPressed: () => _removeVariant(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}