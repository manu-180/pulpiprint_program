// lib/features/products/presentation/widgets/product_image_picker.dart

import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/product_providers.dart';

class ProductImagePicker extends ConsumerStatefulWidget {
  final List<String> images;
  final ValueChanged<List<String>> onImagesChanged;

  const ProductImagePicker({super.key, required this.images, required this.onImagesChanged});

  @override
  ConsumerState<ProductImagePicker> createState() => _ProductImagePickerState();
}

class _ProductImagePickerState extends ConsumerState<ProductImagePicker> {
  bool _isDragging = false;
  bool _isUploading = false;

 // lib/features/products/presentation/widgets/product_image_picker.dart

Future<void> _handleFiles(List<dynamic> files) async {
  if (files.isEmpty) return;
  
  setState(() => _isUploading = true);
  try {
    final repo = ref.read(productsRepositoryProvider);
    List<String> newUrls = [];
    
    for (var file in files) {
      final xFile = file is XFile ? file : XFile(file.path);
      final url = await repo.uploadImage(xFile); // Sube al bucket product_images/uploads
      newUrls.add(url);
    }
    
    // IMPORTANTE: Mantiene las imágenes previas y agrega las nuevas
    widget.onImagesChanged([...widget.images, ...newUrls]);
  } finally {
    if (mounted) setState(() => _isUploading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      // CORRECCIÓN: 'onDone' reemplaza a 'onPerformDrop' en versiones actuales
      onDragDone: (details) => _handleFiles(details.files),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Galería Multimedia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Botón de Carga / Zona de Drop
              InkWell(
                onTap: _isUploading ? null : () async {
                  final files = await ImagePicker().pickMultiImage();
                  if (files.isNotEmpty) _handleFiles(files);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: _isDragging 
                        ? primaryColor.withOpacity(0.1) 
                        : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isDragging ? primaryColor : (isDark ? Colors.white10 : Colors.grey.shade300),
                      width: _isDragging ? 2 : 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _isUploading 
                    ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isDragging ? LucideIcons.filePlus : LucideIcons.uploadCloud, 
                            color: _isDragging ? primaryColor : Colors.grey
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isDragging ? '¡Suelta!' : 'Subir o Arrastrar', 
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10, 
                              fontWeight: FontWeight.w600,
                              color: _isDragging ? primaryColor : Colors.grey
                            )
                          ),
                        ],
                      ),
                ),
              ),

              // Lista de Imágenes existentes
              ...widget.images.asMap().entries.map((entry) {
                final index = entry.key;
                final url = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          final newList = List<String>.from(widget.images)..removeAt(index);
                          widget.onImagesChanged(newList);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                          child: const Icon(LucideIcons.x, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                          ),
                          child: const Text(
                            'PORTADA',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.images.isNotEmpty)
            const Text(
              'Tip: La primera imagen se usará como portada principal.',
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}