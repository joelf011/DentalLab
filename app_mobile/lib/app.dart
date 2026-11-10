import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_service.dart';
import 'features/auth/data/demo_auth.dart';
import 'app_router.dart';

class LabApp extends StatefulWidget {
  const LabApp({super.key, this.authService = const DemoAuth()});

  final AuthService authService;

  @override
  State<LabApp> createState() => _LabAppState();
}

class _LabAppState extends State<LabApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(authService: widget.authService);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Laboratório',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}
