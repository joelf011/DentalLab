import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

// Separador "Conta" da clínica.
class PaginaConta extends StatefulWidget {
  const PaginaConta({super.key});

  @override
  State<PaginaConta> createState() => _PaginaContaState();
}

class _PaginaContaState extends State<PaginaConta> {
  void _terminarSessao() {
    Sessao.atual = null;
    context.go(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    final clinica = Sessao.atual!.clinica!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Conta',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: CoresApp.textoForte,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          clinica.nome,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          clinica.email,
          style: const TextStyle(fontSize: 14, color: CoresApp.textoSuave),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _terminarSessao,
          icon: const Icon(Icons.logout),
          label: const Text('Terminar sessão'),
        ),
      ],
    );
  }
}
