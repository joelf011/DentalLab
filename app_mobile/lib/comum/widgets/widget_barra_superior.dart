import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_logotipo.dart';

// Barra superior das duas vistas: logótipo + nome de quem tem sessão.
// Cada ecrã acrescenta os seus botões em `acoes` (sino, Sair, ...).
// Implementa PreferredSizeWidget para poder ser usada no appBar do Scaffold.
class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const BarraSuperior({super.key, required this.nome, this.acoes = const []});

  final String nome;
  final List<Widget> acoes;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      titleSpacing: 16,
      title: Row(
        children: [
          const Logotipo(largura: 64),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: CoresApp.textoForte,
              ),
            ),
          ),
        ],
      ),
      actions: [...acoes, const SizedBox(width: 8)],
    );
  }
}
