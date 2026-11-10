import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_service.dart';
import '../../client/data/client_demo_data.dart';
import '../../../app_router.dart';

class StaffShell extends StatefulWidget {
  const StaffShell({super.key, required this.session});

  final AuthSession session;

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _StaffHome(name: widget.session.name),
      const _StaffOrders(),
      _StaffAccount(session: widget.session),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Laboratório'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Terminar sessão',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Trabalhos',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Conta',
          ),
        ],
      ),
    );
  }
}

class _StaffHome extends StatelessWidget {
  const _StaffHome({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => _StaffContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bem-vindo, $name',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text('Área de colaborador', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        const Text(
          'Esta área usa dados de demonstração enquanto a API não está disponível.',
          style: TextStyle(fontSize: 14),
        ),
      ],
    ),
  );
}

class _StaffOrders extends StatelessWidget {
  const _StaffOrders();

  @override
  Widget build(BuildContext context) => _StaffContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Trabalhos', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        for (final order in demoOrders)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                order.reference,
                style: const TextStyle(fontSize: 16),
              ),
              subtitle: Text(
                '${order.type} · ${order.statusLabel}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
      ],
    ),
  );
}

class _StaffAccount extends StatelessWidget {
  const _StaffAccount({required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) => _StaffContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Conta', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(session.name, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(session.email, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.go(AppRoutes.login),
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
          icon: const Icon(Icons.logout),
          label: const Text('Terminar sessão'),
        ),
      ],
    ),
  );
}

class _StaffContent extends StatelessWidget {
  const _StaffContent({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: child,
        ),
      ),
    ],
  );
}
