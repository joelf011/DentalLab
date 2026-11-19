import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/cliente/pedidos/widget_cartao_encomenda.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Separador "Início" da clínica: contadores (Iniciar / Processamento /
// Concluído), botão "Nova Encomenda" e as 3 encomendas mais recentes.
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
    final processamento = encomendas.length - iniciar - concluido;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Bem-vindo,',
          style: TextStyle(fontSize: 14, color: CoresApp.textoSuave),
        ),
        Text(
          Sessao.atual!.clinica!.nome,
          style: const TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: CoresApp.textoForte,
          ),
        ),
        const SizedBox(height: 16),
        _Contador(
          texto: 'Iniciar',
          valor: iniciar,
          cor: CoresApp.texto,
          fundo: CoresApp.douradoClaro,
          aoTocar: widget.aoVerPedidos,
        ),
        _Contador(
          texto: 'Processamento',
          valor: processamento,
          cor: CoresApp.info,
          fundo: CoresApp.infoClaro,
          aoTocar: widget.aoVerPedidos,
        ),
        _Contador(
          texto: 'Concluído',
          valor: concluido,
          cor: CoresApp.sucesso,
          fundo: CoresApp.sucessoClaro,
          aoTocar: widget.aoVerPedidos,
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: widget.aoNovaEncomenda,
          icon: const Icon(Icons.add),
          label: const Text('Nova Encomenda'),
        ),
        const SizedBox(height: 24),
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

// Um dos 3 contadores do topo.
class _Contador extends StatelessWidget {
  const _Contador({
    required this.texto,
    required this.valor,
    required this.cor,
    required this.fundo,
    required this.aoTocar,
  });

  final String texto;
  final int valor;
  final Color cor;
  final Color fundo;
  final VoidCallback aoTocar;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: fundo,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: aoTocar,
        title: Text(texto, style: TextStyle(fontSize: 14, color: cor)),
        trailing: Text(
          '$valor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: cor,
          ),
        ),
      ),
    );
  }
}
