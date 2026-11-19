import 'package:flutter/material.dart';

import 'package:app_mobile/comum/widgets/widget_em_construcao.dart';

// Separador "Alertas" da clínica: notificações lidas / não lidas.
// Dados: ServidorCliente.obterNotificacoes(clinicaId).
// Ao tocar numa notificação abre-se a encomenda (Rotas.detalheEncomenda).
class PaginaAlertas extends StatefulWidget {
  const PaginaAlertas({super.key});

  @override
  State<PaginaAlertas> createState() => _PaginaAlertasState();
}

class _PaginaAlertasState extends State<PaginaAlertas> {
  @override
  Widget build(BuildContext context) {
    return const EmConstrucao(titulo: 'Notificações');
  }
}
