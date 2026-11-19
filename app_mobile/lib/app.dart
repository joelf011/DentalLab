import 'package:flutter/material.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/comum/tema/tema_app.dart';

// Configuração geral da aplicação: título, tema e rotas.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Laboratório Catarina Domingos',
      debugShowCheckedModeBanner: false,
      theme: TemaApp.claro,
      routerConfig: rotas,
    );
  }
}
