import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Separador "Início" do colaborador: "Olá, nome", contadores (Ativos /
// Em execução / Urgentes) e as 3 prioridades.
//   Tocar em "Ativos" ou "Em execução" -> widget.aoVerOsMeus()
//   Tocar em "Urgentes" ou "Ver todos" -> context.push(Rotas.prazos)
class PaginaInicioColaborador extends StatefulWidget {
  const PaginaInicioColaborador({super.key, required this.aoVerOsMeus});

  final VoidCallback aoVerOsMeus;

  @override
  State<PaginaInicioColaborador> createState() =>
      _PaginaInicioColaboradorState();
}

class _PaginaInicioColaboradorState extends State<PaginaInicioColaborador> {
  void _verPrazos() {
    context.push(Rotas.prazos);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Olá, ${Sessao.atual!.nome}',
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: CoresApp.textoForte,
          ),
        ),
        const SizedBox(height: 24),
        const EmConstrucao(titulo: 'Prioridades e Urgências'),
        // Provisório: para testar a navegação até aos Prazos.
        TextButton(onPressed: _verPrazos, child: const Text('Ver todos →')),
      ],
    );
  }
}
