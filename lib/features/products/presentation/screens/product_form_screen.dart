// lib/features/products/presentation/screens/product_form_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animate_do/animate_do.dart';
import '../../domain/product_model.dart';
import '../../domain/category_model.dart';
import '../../domain/product_variant.dart';
import '../providers/product_providers.dart';
import '../widgets/product_image_picker.dart';
import '../widgets/category_management_dialog.dart';

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
  final _discountController = TextEditingController(text: '0');
  final _weightController = TextEditingController(text: '0.1');

  List<String> _selectedImages = [];
  bool _isFeatured = false;
  bool _isLoading = false;

  Category? _parentCat;
  Category? _subCat;

  final List<Map<String, TextEditingController>> _variantControllers = [];

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      // Usamos microtask para asegurar que los providers estén listos
      Future.microtask(() => _loadProductData());
    }
  }

  void _loadProductData() {
    final products = ref.read(productsProvider).valueOrNull ?? [];
    try {
      final product = products.firstWhere((p) => p.id == widget.productId);
      
      _titleController.text = product.title;
      _descController.text = product.description ?? '';
      _priceController.text = product.price.toString();
      _discountController.text = product.discount.toString();
      _weightController.text = product.weightKg.toString();
      
      setState(() {
        _selectedImages = List.from(product.images);
        _isFeatured = product.isFeatured;
        
        // Carga precisa de categorías (Principal y Subcategoría)
        if (product.categories.isNotEmpty) {
          final parents = product.categories.where((c) => c.parentId == null).toList();
          if (parents.isNotEmpty) {
            _parentCat = parents.first;
            // Buscamos si hay una subcategoría que pertenezca a este padre
            final subs = product.categories.where((c) => c.parentId == _parentCat?.id).toList();
            if (subs.isNotEmpty) {
              _subCat = subs.first;
            }
          }
        }

        // Carga de variantes existentes
        _variantControllers.clear();
        for (var v in product.variants) {
          _variantControllers.add({
            'size': TextEditingController(text: v.sizeLabel),
            'price': TextEditingController(text: v.price.toString()),
          });
        }
      });
    } catch (e) {
      debugPrint('Error cargando producto: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _weightController.dispose();
    for (var v in _variantControllers) {
      v['size']?.dispose();
      v['price']?.dispose();
    }
    super.dispose();
  }

  void _openCategoryManager() {
    showDialog(
      context: context,
      builder: (context) => const CategoryManagementDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.productId == null ? 'Nuevo Producto' : 'Editar Producto'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _save,
              icon: _isLoading 
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
              ProductImagePicker(
                images: _selectedImages,
                onImagesChanged: (newImages) => setState(() => _selectedImages = newImages),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle(theme, 'Clasificación', LucideIcons.layers),
                  TextButton.icon(
                    onPressed: _openCategoryManager,
                    icon: const Icon(LucideIcons.settings, size: 14),
                    label: const Text('Gestionar'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              categoriesAsync.when(
                data: (all) {
                  final parents = all.where((c) => c.parentId == null).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Categoría Principal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: parents.map((c) => ChoiceChip(
                          label: Text(c.name),
                          selected: _parentCat?.id == c.id,
                          onSelected: (s) => setState(() { 
                            _parentCat = s ? c : null; 
                            _subCat = null; 
                          }),
                        )).toList(),
                      ),
                      if (_parentCat != null) ...[
                        const SizedBox(height: 16),
                        FadeInUp(
                          duration: const Duration(milliseconds: 300),
                          child: _buildSubcatGrid(all),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_,__) => const Text('Error cargando categorías'),
              ),

              const Divider(height: 48),

              _buildSectionTitle(theme, 'Información General', LucideIcons.info),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController, 
                decoration: const InputDecoration(labelText: 'Nombre del Producto'),
                validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController, 
                decoration: const InputDecoration(labelText: 'Descripción', alignLabelWithHint: true), 
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              _buildSectionTitle(theme, 'Valores y Logística', LucideIcons.dollarSign),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (_variantControllers.isEmpty)
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(labelText: 'Precio Base', prefixText: '\$ ', filled: true),
                        keyboardType: TextInputType.number,
                        validator: (v) => (_variantControllers.isEmpty && v!.isEmpty) ? 'Requerido' : null,
                      ),
                    ),
                  if (_variantControllers.isEmpty) const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _discountController,
                      decoration: const InputDecoration(labelText: 'Descuento', suffixText: '%', filled: true),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Peso (kg)', suffixText: 'kg', filled: true),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SwitchListTile(
                title: const Text('Producto Destacado'),
                subtitle: const Text('Se mostrará en la sección principal.'),
                value: _isFeatured,
                onChanged: (v) => setState(() => _isFeatured = v),
                secondary: Icon(LucideIcons.star, color: _isFeatured ? Colors.amber : Colors.grey),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade300)
                ),
              ),

              const Divider(height: 48),

              _buildVariantsEditor(theme),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(title.toUpperCase(), 
          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
      ],
    );
  }

  Widget _buildSubcatGrid(List<Category> all) {
    final subs = all.where((c) => c.parentId == _parentCat!.id).toList();
    if (subs.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subcategoría (Opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: subs.map((c) => ChoiceChip(
            label: Text(c.name),
            selected: _subCat?.id == c.id,
            selectedColor: Colors.deepPurple.withOpacity(0.2),
            onSelected: (s) => setState(() => _subCat = s ? c : null),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildVariantsEditor(ThemeData theme) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(theme, 'Variantes / Talles', LucideIcons.list),
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _variantControllers.add({
                'size': TextEditingController(), 
                'price': TextEditingController()
              })), 
              icon: const Icon(LucideIcons.plus, size: 16), 
              label: const Text('Agregar Talle')
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._variantControllers.asMap().entries.map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: FadeInLeft(
            duration: const Duration(milliseconds: 200),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: entry.value['size'], 
                    decoration: const InputDecoration(labelText: 'Etiqueta (ej: XL)', filled: true)
                  )
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: entry.value['price'], 
                    decoration: const InputDecoration(labelText: 'Precio', prefixText: '\$ ', filled: true),
                    keyboardType: TextInputType.number,
                  )
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => setState(() => _variantControllers.removeAt(entry.key)), 
                  icon: const Icon(LucideIcons.trash2, color: Colors.red, size: 20)
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

 Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_parentCat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes seleccionar al menos una categoría principal'), 
          backgroundColor: Colors.orange
        )
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final List<Category> cats = [_parentCat!];
      if (_subCat != null) cats.add(_subCat!);

      final variants = _variantControllers.map((v) => ProductVariant(
        sizeLabel: v['size']!.text,
        price: double.tryParse(v['price']!.text) ?? 0.0,
      )).toList();

      double finalBasePrice = double.tryParse(_priceController.text) ?? 0.0;
      if (variants.isNotEmpty) {
        finalBasePrice = variants.map((v) => v.price).reduce(min);
      }

      final product = Product(
        id: widget.productId,
        title: _titleController.text,
        description: _descController.text,
        price: finalBasePrice,
        discount: int.tryParse(_discountController.text) ?? 0,
        images: _selectedImages,
        weightKg: double.tryParse(_weightController.text) ?? 0.1,
        isFeatured: _isFeatured,
        categories: cats,
        variants: variants,
      );

      await ref.read(productsProvider.notifier).saveProduct(product);
      
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guardado exitosamente'), 
            backgroundColor: Colors.green
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'), 
            backgroundColor: Colors.red
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}