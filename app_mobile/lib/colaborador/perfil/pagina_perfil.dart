import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

// Separador "Perfil" do colaborador.
class PaginaPerfil extends StatefulWidget {
  const PaginaPerfil({super.key});

  @override
  State<PaginaPerfil> createState() => _PaginaPerfilState();
}

class _PaginaPerfilState extends State<PaginaPerfil> {
  void _terminarSessao() {
    Sessao.atual = null;
    context.go(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    final sessao = Sessao.atual!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Perfil',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: CoresApp.textoForte,
          ),
        ),
        const SizedBox(height: 16),
        Text(sessao.nome, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Text(sessao.email, style: const TextStyle(fontSize: 14)),
        Text(sessao.cargo, style: const TextStyle(fontSize: 14)),
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
