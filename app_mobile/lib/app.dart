import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';

class LabApp extends StatelessWidget {
  const LabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaboratÃ³rio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
