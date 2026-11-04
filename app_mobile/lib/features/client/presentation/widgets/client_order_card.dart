import 'package:flutter/material.dart';

import '../../data/client_demo_data.dart';

class ClientOrderCard extends StatelessWidget {
  const ClientOrderCard({super.key, required this.order, required this.onOpen});

  final ClientOrder order;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final completed = order.status == 'concluido';
    final inProgress = const [
      'em_producao',
      'em_standby',
      'aguarda_aprovacao',
    ].contains(order.status);
    final statusText = completed
        ? 'Concluído'
        : inProgress
        ? 'Processamento'
        : 'Iniciar';
    final statusColor = completed
        ? const Color(0xFF047857)
        : inProgress
        ? const Color(0xFF1D4ED8)
        : const Color(0xFF475569);
    final statusBackground = completed
        ? const Color(0xFFECFDF5)
        : inProgress
        ? const Color(0xFFEFF6FF)
        : const Color(0xFFF1F5F9);

    return Material(
      color: Colors.white,
      elevation: 3,
      shadowColor: const Color(0x180F172A),
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFFE9EAEC)),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 120),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.patient,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFF9A6B20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  order.type,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '• $statusText',
                        maxLines: 1,
                        style: TextStyle(fontSize: 14, color: statusColor),
                      ),
                    ),
                    if (order.delivery != null)
                      Text(
                        'Entrega ${order.delivery}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
