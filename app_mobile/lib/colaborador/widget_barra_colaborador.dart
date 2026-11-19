import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Barra inferior do colaborador, com 4 separadores (NavigationBar).
class BarraColaborador extends StatelessWidget {
  const BarraColaborador({
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
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment),
          label: 'Disponíveis',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Os Meus',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
