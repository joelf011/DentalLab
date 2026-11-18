import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/cliente/inicio/widget_contador.dart';
import 'package:app_mobile/cliente/pedidos/widget_cartao_encomenda.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Separador "Início" da clínica: contadores (Iniciar / Processamento /
// Concluído), botão "Nova Encomenda" e as 3 primeiras encomendas do servidor.
class PaginaInicioCliente extends StatefulWidget {
  const PaginaInicioCliente({
    super.key,
    required this.aoVerPedidos,
    required this.aoNovaEncomenda,
  });

  final VoidCallback aoVerPedidos;
  final VoidCallback aoNovaEncomenda;

  @override
  State<PaginaInicioCliente> createState() => _PaginaInicioClienteState();
}

class _PaginaInicioClienteState extends State<PaginaInicioCliente> {
  final _servidor = const ServidorCliente();
  late Future<List<Encomenda>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servidor.obterEncomendas(Sessao.atual!.clinica!.id);
  }

  void _abrirEncomenda(Encomenda encomenda) {
    context.push(Rotas.detalheEncomenda, extra: encomenda);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Encomenda>>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _conteudo(snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _conteudo(List<Encomenda> encomendas) {
    final iniciar = encomendas
        .where((e) => e.estado == 'por_receber' || e.estado == 'encaminhado')
        .length;
    final concluido = encomendas.where((e) => e.estado == 'concluido').length;
    final processamento = encomendas
        .where(
          (e) =>
              e.estado == 'em_producao' ||
              e.estado == 'em_standby' ||
              e.estado == 'aguarda_aprovacao',
        )
        .length;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Bem-vindo,',
          style: TextStyle(fontSize: 13, color: CoresApp.textoSuave),
        ),
        Text(
          Sessao.atual!.clinica!.nome,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: CoresApp.textoForte,
          ),
        ),
        const SizedBox(height: 20),
        Contador(
          texto: 'Iniciar',
          valor: iniciar,
          cor: CoresApp.douradoEscuro,
          fundo: CoresApp.douradoClaro,
          aoTocar: widget.aoVerPedidos,
        ),
        Contador(
          texto: 'Processamento',
          valor: processamento,
          cor: CoresApp.info,
          fundo: CoresApp.infoClaro,
          aoTocar: widget.aoVerPedidos,
        ),
        Contador(
          texto: 'Concluído',
          valor: concluido,
          cor: CoresApp.sucesso,
          fundo: CoresApp.sucessoClaro,
          aoTocar: widget.aoVerPedidos,
        ),
        const SizedBox(height: 10),
        FilledButton(
          onPressed: widget.aoNovaEncomenda,
          style: FilledButton.styleFrom(
            backgroundColor: CoresApp.dourado,
            foregroundColor: CoresApp.textoForte,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            minimumSize: const Size(64, 64),
          ),
          child: const Row(
            children: [
              Expanded(
                child: Text(
                  'Nova Encomenda',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              SizedBox(width: 12),
              Icon(Icons.add, size: 28),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Encomendas Recentes',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: CoresApp.textoForte,
                ),
              ),
            ),
            TextButton(
              onPressed: widget.aoVerPedidos,
              style: TextButton.styleFrom(
                foregroundColor: CoresApp.douradoEscuro,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Ver todos →'),
            ),
          ],
        ),
        if (encomendas.isEmpty)
          const EstadoVazio(mensagem: 'Ainda não há encomendas.')
        else
          for (final encomenda in encomendas.take(3))
            CartaoEncomenda(encomenda: encomenda, aoAbrir: _abrirEncomenda),
      ],
    );
  }
}
