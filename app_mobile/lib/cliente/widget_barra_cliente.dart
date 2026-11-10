import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Barra inferior da clínica, com 5 separadores (NavigationBar).
class BarraCliente extends StatelessWidget {
  const BarraCliente({
    super.key,
    required this.indiceAtual,
    required this.aoSelecionar,
  });

  final int indiceAtual;
  final ValueChanged<int> aoSelecionar;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: indiceAtual,
      onDestinationSelected: aoSelecionar,
      backgroundColor: CoresApp.superficie,
      indicatorColor: CoresApp.douradoClaro,
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
}
