import 'package:flutter/material.dart';

import '../data/client_demo_data.dart';
import 'client_dashboard_page.dart';
import 'widgets/client_bottom_navigation.dart';
import 'widgets/client_order_card.dart';

class ClientShell extends StatefulWidget {
  const ClientShell({super.key, required this.clinic});

  final ClientClinic clinic;

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _selectedIndex = 0;

  List<ClientOrder> get _clinicOrders =>
      demoOrders.where((order) => order.clinicId == widget.clinic.id).toList();

  void _showOrder(ClientOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.reference,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(order.type, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  'Paciente: ${order.patient}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estado: ${order.statusLabel}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  'Etapa: ${order.stage}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ClientDashboardPage(
        clinic: widget.clinic,
        orders: _clinicOrders,
        onShowOrders: () => setState(() => _selectedIndex = 1),
        onNewOrder: () => setState(() => _selectedIndex = 2),
        onSelectOrder: _showOrder,
      ),
      _OrdersPage(orders: _clinicOrders, onSelectOrder: _showOrder),
      const _FeaturePage(
        icon: Icons.add_circle_outline,
        title: 'Nova Encomenda',
        message: 'O formulário de nova encomenda será ligado nesta área.',
      ),
      const _FeaturePage(
        icon: Icons.notifications_none_outlined,
        title: 'Alertas',
        message: 'As notificações da clínica serão apresentadas aqui.',
      ),
      _AccountPage(
        clinic: widget.clinic,
        onSignOut: () => Navigator.of(context).pop(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        titleSpacing: 16,
        title: Row(
          children: [
            SizedBox(
              width: 64,
              height: 40,
              child: ClipRect(
                child: Transform.scale(
                  scale: 1.2,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      width: 64,
                      height: 64,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.clinic.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tema',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            style: IconButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE5E7EB)),
              shape: const CircleBorder(),
            ),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tema escuro em preparação.')),
            ),
            icon: const Icon(Icons.dark_mode_outlined, size: 20),
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'Alertas',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: () => setState(() => _selectedIndex = 3),
                icon: const Icon(Icons.notifications_none_outlined, size: 24),
              ),
              const Positioned(
                right: 4,
                top: 4,
                child: IgnorePointer(
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Color(0xFFC9A45E),
                    child: Text(
                      '3',
                      style: TextStyle(fontSize: 12, color: Color(0xFF111827)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ClientBottomNavigation(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersPage extends StatelessWidget {
  const _OrdersPage({required this.orders, required this.onSelectOrder});

  final List<ClientOrder> orders;
  final ValueChanged<ClientOrder> onSelectOrder;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Encomendas',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 24),
              if (orders.isEmpty)
                const Text(
                  'Ainda não há encomendas.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                )
              else
                for (final order in orders) ...[
                  ClientOrderCard(
                    order: order,
                    onOpen: () => onSelectOrder(order),
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _FeaturePage extends StatelessWidget {
  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Icon(icon, size: 48, color: const Color(0xFFC9A227)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AccountPage extends StatelessWidget {
  const _AccountPage({required this.clinic, required this.onSignOut});

  final ClientClinic clinic;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conta',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                clinic.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                clinic.email,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: onSignOut,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(64, 48),
                  foregroundColor: const Color(0xFF1F2937),
                ),
                icon: const Icon(Icons.logout),
                label: const Text(
                  'Terminar sessão',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
