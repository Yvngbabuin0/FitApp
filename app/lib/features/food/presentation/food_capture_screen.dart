import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../application/food_controller.dart';

/// Captura una foto de la comida (cámara o galería) para analizarla.
class FoodCaptureScreen extends ConsumerStatefulWidget {
  const FoodCaptureScreen({super.key});

  @override
  ConsumerState<FoodCaptureScreen> createState() => _FoodCaptureScreenState();
}

class _FoodCaptureScreenState extends ConsumerState<FoodCaptureScreen> {
  bool _loading = false;

  Future<void> _pick(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    final bytes = Uint8List.fromList(await picked.readAsBytes());
    setState(() => _loading = true);
    final items =
        await ref.read(foodControllerProvider.notifier).analyze(bytes);
    if (!mounted) return;

    setState(() => _loading = false);
    if (!mounted) return;
    context.push('/food/review', extra: items);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Comidas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  'Analiza una foto para registrar tu comida',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('camera-button'),
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Tomar foto'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('gallery-button'),
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Elegir de la galería'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  key: const Key('daily-log-button'),
                  onPressed: () => context.go('/food/log'),
                  icon: const Icon(Icons.book),
                  label: const Text('Ver diario'),
                ),
              ],
            ),
    );
  }
}