import 'package:flutter/material.dart';

class ClientBottomNavigation extends StatelessWidget {
  const ClientBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    backgroundColor: Colors.white,
    indicatorColor: const Color(0xFFF7F2E7),
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view),
        label: 'Início',
      ),
      NavigationDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: 'Pedidos',
      ),
      NavigationDestination(
        icon: Icon(Icons.add_circle_outline),
        selectedIcon: Icon(Icons.add_circle),
        label: 'Novo',
      ),
      NavigationDestination(
        icon: Icon(Icons.notifications_none_outlined),
        selectedIcon: Icon(Icons.notifications),
        label: 'Alertas',
      ),
      NavigationDestination(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Conta',
      ),
    ],
  );
}
