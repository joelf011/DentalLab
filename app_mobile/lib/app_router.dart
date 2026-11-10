import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/data/auth_service.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/client/data/client_demo_data.dart';
import 'features/client/presentation/client_order_detail_page.dart';
import 'features/client/presentation/client_shell.dart';
import 'features/colaborador/presentation/staff_shell.dart';

abstract final class AppRoutes {
  static const login = '/';
  static const client = '/client';
  static const staff = '/staff';
  static const clientOrder = '/client/order';
}

GoRouter createAppRouter({required AuthService authService}) => GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginPage(authService: authService),
    ),
    GoRoute(
      path: AppRoutes.client,
      builder: (context, state) {
        final session = state.extra;
        if (session is AuthSession &&
            session.role == AuthRole.client &&
            session.clinic != null) {
          return ClientShell(session: session);
        }
        return const _SessionRequiredPage();
      },
    ),
    GoRoute(
      path: AppRoutes.staff,
      builder: (context, state) {
        final session = state.extra;
        if (session is AuthSession && session.role == AuthRole.collaborator) {
          return StaffShell(session: session);
        }
        return const _SessionRequiredPage();
      },
    ),
    GoRoute(
      path: AppRoutes.clientOrder,
      builder: (context, state) {
        final order = state.extra;
        if (order is ClientOrder) {
          return ClientOrderDetailPage(order: order);
        }
        return const _SessionRequiredPage();
      },
    ),
  ],
);

class _SessionRequiredPage extends StatelessWidget {
  const _SessionRequiredPage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('A sessao terminou. Inicie sessao novamente.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Ir para o inicio de sessao'),
            ),
          ],
        ),
      ),
    ),
  );
}
