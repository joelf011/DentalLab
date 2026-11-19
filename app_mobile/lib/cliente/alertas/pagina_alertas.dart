import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/cliente/alertas/widget_cartao_notificacao.dart';
import 'package:app_mobile/cliente/dados/notificacao.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Separador "Alertas" da clínica: notificações lidas e por ler.
// Ao tocar numa notificação, fica lida e abre-se a encomenda.
// aoMudar: avisa o EcraCliente para atualizar o número do sino.
class PaginaAlertas extends StatefulWidget {
  const PaginaAlertas({super.key, required this.aoMudar});

  final VoidCallback aoMudar;

  @override
  State<PaginaAlertas> createState() => _PaginaAlertasState();
}

class _PaginaAlertasState extends State<PaginaAlertas> {
  final _servidor = const ServidorCliente();
  late Future<List<Notificacao>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servidor.obterNotificacoes();
  }

  // Volta a pedir as notificações e atualiza o sino.
  void _recarregar() {
    setState(() {
      _futuro = _servidor.obterNotificacoes();
    });
    widget.aoMudar();
  }

  Future<void> _marcarTodasLidas() async {
    await _servidor.marcarTodasLidas();
    if (!mounted) return;
    _recarregar();
  }

  Future<void> _abrirNotificacao(Notificacao notificacao) async {
    await _servidor.marcarNotificacaoLida(notificacao.id);
    final ordemId = notificacao.ordemTrabalhoId;
    final encomenda = ordemId == null
        ? null
        : await _servidor.obterEncomenda(ordemId);
    if (!mounted) return;
    _recarregar();
    if (encomenda != null) {
      context.push(Rotas.detalheEncomenda, extra: encomenda);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Notificacao>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _lista(snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _lista(List<Notificacao> notificacoes) {
    final porLer = notificacoes.where((n) => !n.lida).length;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notificações',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      color: CoresApp.textoForte,
                    ),
                  ),
                  if (porLer > 0)
                    Text(
                      porLer == 1 ? '1 não lida' : '$porLer não lidas',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CoresApp.douradoEscuro,
                      ),
                    ),
                ],
              ),
            ),
            if (porLer > 0)
              TextButton(
                onPressed: _marcarTodasLidas,
                child: const Text('Marcar todas como lidas'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (notificacoes.isEmpty)
          const EstadoVazio(
            mensagem: 'Sem notificações',
            icone: Icons.notifications_off_outlined,
          )
        else
          for (final notificacao in notificacoes)
            CartaoNotificacao(
              notificacao: notificacao,
              aoAbrir: _abrirNotificacao,
            ),
      ],
    );
  }
}
