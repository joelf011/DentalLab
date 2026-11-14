import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/cliente/pedidos/widget_cartao_encomenda.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_estado_vazio.dart';

// Separador "Pedidos" da clínica: todas as encomendas da clínica.
class PaginaPedidos extends StatefulWidget {
  const PaginaPedidos({super.key});

  @override
  State<PaginaPedidos> createState() => _PaginaPedidosState();
}

class _PaginaPedidosState extends State<PaginaPedidos> {
  final _servidor = const ServidorCliente();
  late Future<List<Encomenda>> _futuro;
  late TextEditingController _controladorPesquisa;
  String _estado = 'Todos';
  String _tipo = '';
  String _prazo = '';

  // Compatibilidade com os estados ainda devolvidos pela demonstração.
  static const _iniciar = {
    'iniciar',
    'em avaliação',
    'por iniciar',
    'por_receber',
    'encaminhado',
  };
  static const _processamento = {
    'processamento',
    'em processamento',
    'em espera',
    'em prova',
    'em_producao',
    'em_standby',
    'aguarda_aprovacao',
  };
  static const _concluido = {'concluído', 'concluido', 'entregue'};

  @override
  void initState() {
    super.initState();
    _controladorPesquisa = TextEditingController();
    _controladorPesquisa.addListener(_atualizarPesquisa);
    _futuro = _servidor.obterEncomendas(Sessao.atual!.clinica!.id);
  }

  @override
  void dispose() {
    _controladorPesquisa.removeListener(_atualizarPesquisa);
    _controladorPesquisa.dispose();
    super.dispose();
  }

  void _atualizarPesquisa() => setState(() {});

  void _selecionarTodos(bool selecionado) => setState(() => _estado = 'Todos');
  void _selecionarIniciar(bool selecionado) =>
      setState(() => _estado = 'Iniciar');
  void _selecionarProcessamento(bool selecionado) =>
      setState(() => _estado = 'Processamento');
  void _selecionarConcluido(bool selecionado) =>
      setState(() => _estado = 'Concluído');
  void _selecionarTipo(String? valor) => setState(() => _tipo = valor ?? '');
  void _selecionarPrazo(String? valor) => setState(() => _prazo = valor ?? '');

  void _limparFiltros() {
    setState(() {
      _estado = 'Todos';
      _tipo = '';
      _prazo = '';
    });
  }

  String _normalizar(String texto) =>
      texto.trim().toLowerCase().replaceAll('í', 'i');

  bool _corresponde(Encomenda encomenda, DateTime hoje) {
    final pesquisa = _normalizar(_controladorPesquisa.text);
    final correspondePesquisa = [
      encomenda.referencia,
      encomenda.paciente,
      encomenda.medico ?? '',
    ].any((texto) => _normalizar(texto).contains(pesquisa));
    final estado = encomenda.estado.trim().toLowerCase();
    final correspondeEstado = switch (_estado) {
      'Iniciar' => _iniciar.contains(estado),
      'Processamento' => _processamento.contains(estado),
      'Concluído' => _concluido.contains(estado),
      _ => true,
    };
    if (!correspondePesquisa || !correspondeEstado) return false;
    if (_tipo.isNotEmpty && encomenda.tipo != _tipo) return false;
    if (_prazo.isEmpty) return true;
    if (_concluido.contains(estado) || encomenda.prazo == null) return false;
    final prazoLocal = encomenda.prazo!.toLocal();
    final dia = DateTime(prazoLocal.year, prazoLocal.month, prazoLocal.day);
    if (_prazo == 'excedido') return dia.isBefore(hoje);
    // Inclui hoje e o sétimo dia, sem depender da hora de entrega.
    final limite = DateTime(hoje.year, hoje.month, hoje.day + 7);
    return !dia.isBefore(hoje) && !dia.isAfter(limite);
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
          return _lista(snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _lista(List<Encomenda> encomendas) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final filtradas = encomendas.where((e) => _corresponde(e, hoje)).toList();
    final tipos =
        encomendas
            .map((e) => e.tipo)
            .where((tipo) => tipo.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final numeroFiltros = [
      _tipo,
      _prazo,
    ].where((valor) => valor.isNotEmpty).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Encomendas',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            color: CoresApp.textoForte,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controladorPesquisa,
          decoration: const InputDecoration(
            hintText: 'Pesquisar por identificador, ref...',
            labelText: 'Pesquisar por referência, paciente ou médico',
            prefixIcon: Icon(Icons.search, color: CoresApp.textoSuave),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _filtroEstado('Todos', _selecionarTodos),
            _filtroEstado('Iniciar', _selecionarIniciar),
            _filtroEstado('Processamento', _selecionarProcessamento),
            _filtroEstado('Concluído', _selecionarConcluido),
          ],
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 12, bottom: 12),
          title: Text(
            numeroFiltros == 0
                ? 'Filtros avançados'
                : 'Filtros avançados · $numeroFiltros',
          ),
          children: [
            _seletor('Tipo', _tipo, {
              '': 'Todos os tipos',
              for (final tipo in tipos) tipo: tipo,
            }, _selecionarTipo),
            const SizedBox(height: 12),
            _seletor('Prazo', _prazo, {
              '': 'Todos os prazos',
              'excedido': 'Prazo excedido',
              'proximos': 'Próximos 7 dias',
            }, _selecionarPrazo),
            if (numeroFiltros > 0 || _estado != 'Todos')
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _limparFiltros,
                  child: const Text('Limpar filtros'),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (filtradas.isEmpty)
          const EstadoVazio(
            mensagem: 'Sem resultados',
            dica: 'Tente ajustar a pesquisa ou filtros',
          )
        else
          for (final encomenda in filtradas)
            CartaoEncomenda(encomenda: encomenda, aoAbrir: _abrirEncomenda),
      ],
    );
  }

  Widget _filtroEstado(String texto, ValueChanged<bool> aoSelecionar) {
    return ChoiceChip(
      label: Text(texto),
      selected: _estado == texto,
      onSelected: aoSelecionar,
      selectedColor: CoresApp.douradoClaro,
      backgroundColor: CoresApp.superficie,
      labelStyle: TextStyle(
        color: _estado == texto ? CoresApp.douradoEscuro : CoresApp.texto,
      ),
      shape: const StadiumBorder(),
      showCheckmark: false,
    );
  }

  Widget _seletor(
    String titulo,
    String valor,
    Map<String, String> opcoes,
    ValueChanged<String?> aoSelecionar,
  ) {
    return InputDecorator(
      decoration: InputDecoration(labelText: titulo),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          isDense: true,
          items: [
            for (final opcao in opcoes.entries)
              DropdownMenuItem(value: opcao.key, child: Text(opcao.value)),
          ],
          onChanged: aoSelecionar,
        ),
      ),
    );
  }
}
