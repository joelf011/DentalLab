import 'package:flutter/material.dart';

import '../data/client_demo_data.dart';
import 'widgets/client_order_card.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({
    super.key,
    required this.clinic,
    required this.orders,
    required this.onShowOrders,
    required this.onNewOrder,
    required this.onSelectOrder,
  });

  final ClientClinic clinic;
  final List<ClientOrder> orders;
  final VoidCallback onShowOrders;
  final VoidCallback onNewOrder;
  final ValueChanged<ClientOrder> onSelectOrder;

  @override
  Widget build(BuildContext context) {
    final clinicOrders = orders
        .where((order) => order.clinicId == clinic.id)
        .toList();
    final iniciar = clinicOrders
        .where(
          (order) =>
              order.status == 'por_receber' || order.status == 'encaminhado',
        )
        .length;
    final processamento = clinicOrders
        .where(
          (order) =>
              order.status == 'em_producao' ||
              order.status == 'em_standby' ||
              order.status == 'aguarda_aprovacao',
        )
        .length;
    final concluido = clinicOrders
        .where((order) => order.status == 'concluido')
        .length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bem-vindo,',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  clinic.name,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryCard(
                  label: 'Iniciar',
                  value: iniciar,
                  background: const Color(0xFFF7F2E7),
                  border: const Color(0xFFEDE8DE),
                  valueColor: const Color(0xFF111827),
                  onTap: onShowOrders,
                ),
                const SizedBox(height: 8),
                _SummaryCard(
                  label: 'Processamento',
                  value: processamento,
                  background: const Color(0xFFEFF6FF),
                  border: const Color(0xFFE2ECF8),
                  valueColor: const Color(0xFF1D4ED8),
                  onTap: onShowOrders,
                ),
                const SizedBox(height: 8),
                _SummaryCard(
                  label: 'Concluído',
                  value: concluido,
                  background: const Color(0xFFECFDF5),
                  border: const Color(0xFFDDF3E9),
                  valueColor: const Color(0xFF047857),
                  onTap: onShowOrders,
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: onNewOrder,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        backgroundColor: const Color(0xFFC9A45E),
                        foregroundColor: const Color(0xFF111827),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Nova Encomenda',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.add, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Encomendas Recentes',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onShowOrders,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 48),
                        foregroundColor: const Color(0xFF9A6B20),
                      ),
                      child: const Text(
                        'Ver todos →',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (clinicOrders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Ainda não há encomendas.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  )
                else
                  for (final order in clinicOrders.take(3)) ...[
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
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.background,
    required this.border,
    required this.valueColor,
    required this.onTap,
  });

  final String label;
  final int value;
  final Color background;
  final Color border;
  final Color valueColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: background,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: border),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: valueColor)),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
