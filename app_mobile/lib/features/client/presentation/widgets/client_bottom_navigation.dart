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
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    elevation: 8,
    child: SizedBox(
      height: 64,
      child: Row(
        children: [
          _item(0, 'Início', Icons.grid_view_outlined),
          _item(1, 'Pedidos', Icons.inventory_2_outlined),
          _item(2, 'Novo', Icons.add),
          _item(3, 'Alertas', Icons.notifications_none_outlined, showDot: true),
          _item(4, 'Conta', Icons.person_outline),
        ],
      ),
    ),
  );

  Widget _item(int index, String label, IconData icon, {bool showDot = false}) {
    final selected = selectedIndex == index;
    final isNew = index == 2;
    final color = isNew
        ? const Color(0xFF1F2937)
        : selected
        ? const Color(0xFF8B6A36)
        : const Color(0xFF64748B);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: isNew
              ? const Color(0xFFC9A45E)
              : selected
              ? const Color(0xFFF7F2E7)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onDestinationSelected(index),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 64),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: isNew ? 28 : 22, color: color),
                      if (showDot)
                        const Positioned(
                          right: -2,
                          top: -2,
                          child: CircleAvatar(
                            radius: 3,
                            backgroundColor: Color(0xFFC9A45E),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: selected || isNew
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
