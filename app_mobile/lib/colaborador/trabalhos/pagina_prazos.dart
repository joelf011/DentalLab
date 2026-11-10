import 'package:flutter/material.dart';

import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// "Gestão de Prazos": todos os trabalhos urgentes (Trabalho.eUrgente),
// do prazo mais próximo para o mais distante.
// Rota: Rotas.prazos (abre por cima, com seta para voltar).
class PaginaPrazos extends StatefulWidget {
  const PaginaPrazos({super.key});

  @override
  State<PaginaPrazos> createState() => _PaginaPrazosState();
}

class _PaginaPrazosState extends State<PaginaPrazos> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestão de Prazos')),
      body: const EmConstrucao(titulo: 'Gestão de Prazos'),
    );
  }
}
