// lib/features/products/presentation/widgets/product_image_picker.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../data/products_repository.dart';
import '../providers/product_providers.dart';

class ProductImagePicker extends ConsumerStatefulWidget {
  final TextEditingController urlController;

  const ProductImagePicker({super.key, required this.urlController});

  @override
  ConsumerState<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends ConsumerState<ProductImagePicker> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isUploading = true);
      final repository = ref.read(productsRepositoryProvider);
      
      // Subida real a Supabase
      final publicUrl = await repository.uploadImage(image);

      widget.urlController.text = publicUrl;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen cargada'), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

 @override
  Widget build(BuildContext context) {
    final currentUrl = widget.urlController.text;
    final hasImage = currentUrl.isNotEmpty;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Colores dinámicos según el tema
    final containerColor = isDark ? const Color(0xFF252525) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Multimedia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        
        Container(
          height: 140, 
          decoration: BoxDecoration(
            color: containerColor, // SE ADAPTA AL TEMA
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
            // Sombra suave solo en modo claro, en oscuro la quitamos o hacemos muy sutil
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Row(
            children: [
              // 1. PREVIEW
              AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    image: hasImage 
                      ? DecorationImage(image: NetworkImage(currentUrl), fit: BoxFit.cover) 
                      : null,
                  ),
                  child: hasImage 
                      ? null 
                      : Icon(LucideIcons.image, color: theme.disabledColor, size: 32),
                ),
              ),

              // 2. ACCIONES
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isUploading) ...[
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text('Subiendo...', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                      ] else ...[
                        Text(
                          hasImage ? 'Imagen lista' : 'Sin imagen',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasImage ? 'Se ve genial.' : 'Sube una foto (Max 5MB).',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _pickAndUpload,
                            icon: Icon(hasImage ? LucideIcons.refreshCw : LucideIcons.uploadCloud, size: 16),
                            label: Text(hasImage ? 'Cambiar' : 'Subir'),
                            style: OutlinedButton.styleFrom(
                              // En modo oscuro, el borde del botón más sutil
                              side: BorderSide(color: isDark ? Colors.white24 : theme.primaryColor.withOpacity(0.5)),
                              foregroundColor: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}