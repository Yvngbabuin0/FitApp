import 'package:flutter/material.dart';

/// Pantalla de inicio provisional; la navegación principal real se monta en la
/// Task 20 (pestañas: entrenos, comida, progreso).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fitness Tracker')),
      body: const Center(child: Text('Aquí irá la navegación principal')),
    );
  }
}