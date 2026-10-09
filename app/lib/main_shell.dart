import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Marco principal de la app: navegación inferior con cuatro pestañas
/// (Comidas, Entrenos, Progreso, Perfil).
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.restaurant),
            label: 'Comidas',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center),
            label: 'Entrenos',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}