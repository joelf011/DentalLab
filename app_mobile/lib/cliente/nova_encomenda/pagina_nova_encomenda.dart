import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Nova encomenda: passo 1 (encomenda), passo 2 (trabalhos) e
// "Encomenda enviada". Rota: Rotas.novaEncomenda (abre por cima, sem barra).
//
// Como sair deste ecrã:
//   context.pop(true)  -> encomenda enviada: a app mostra o separador Pedidos
//   context.pop(false) -> cancelada: a app volta ao separador onde estava
class PaginaNovaEncomenda extends StatefulWidget {
  const PaginaNovaEncomenda({super.key});

  @override
  State<PaginaNovaEncomenda> createState() => _PaginaNovaEncomendaState();
}

class _PaginaNovaEncomendaState extends State<PaginaNovaEncomenda> {
  void _cancelar() {
    context.pop(false);
  }

  // Provisório: simula o envio para testar a navegação.
  void _simularEnvio() {
    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova encomenda'),
        leading: IconButton(
          tooltip: 'Cancelar',
          onPressed: _cancelar,
          icon: const Icon(Icons.close),
        ),
      ),
      body: Column(
        children: [
          const Expanded(child: EmConstrucao(titulo: 'Nova encomenda')),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FilledButton(
              onPressed: _simularEnvio,
              child: const Text('Simular envio'),
            ),
          ),
        ],
      ),
    );
  }
}
