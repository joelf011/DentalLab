import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/dados_demo_cliente.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/encomenda_nova.dart';
import 'package:app_mobile/cliente/dados/notificacao.dart';
import 'package:app_mobile/configuracao.dart';

// Pedidos de dados da vista da clínica. O url da API vem no construtor e
// cada método é uma tarefa assíncrona (Future).
// Enquanto usarDadosDemo for true, devolvem os dados de demonstração;
// depois passam a usar http.get / http.post + jsonDecode.
// A clínica só recebe as suas encomendas: a API sabe quem é pelo token.
class ServidorCliente {
  const ServidorCliente({this.url = urlApi});

  final String url;

  // Simula o tempo de resposta da API.
  Future<void> _esperar() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  int get _clienteId => Sessao.atual!.clinica!.id;

  // GET /api/ordens (com os trabalhos e comentários de cada ordem)
  Future<List<Encomenda>> obterEncomendas() async {
    await _esperar();
    return encomendasDemo
        .where((encomenda) => encomenda.clienteId == _clienteId)
        .toList();
  }

  // Notificações de quem tem sessão, das mais recentes para as mais antigas.
  Future<List<Notificacao>> obterNotificacoes() async {
    await _esperar();
    final idsDaClinica = encomendasDemo
        .where((encomenda) => encomenda.clienteId == _clienteId)
        .map((encomenda) => encomenda.id)
        .toSet();
    final lista = notificacoesDemo
        .where((n) => idsDaClinica.contains(n.ordemTrabalhoId))
        .toList();
    lista.sort((a, b) => b.dataCriacao.compareTo(a.dataCriacao));
    return lista;
  }

  // Preenche data_leitura de uma notificação.
  Future<void> marcarNotificacaoLida(int notificacaoId) async {
    await _esperar();
  }

  // Preenche data_leitura de todas as notificações por ler.
  Future<void> marcarTodasLidas() async {
    await _esperar();
  }

  // GET /api/tipos-trabalho (só os ativos)
  Future<List<TipoTrabalho>> obterTiposTrabalho() async {
    await _esperar();
    return tiposTrabalhoDemo;
  }

  // POST /api/ordens e POST /api/ordens/:id/trabalhos.
  // Devolve o número da nova ordem. A ordem começa "Em avaliação".
  Future<int> enviarEncomenda(EncomendaNova nova) async {
    await _esperar();
    final id = encomendasDemo.last.id + 1;
    // Na demonstração, a encomenda passa a aparecer nos Pedidos.
    encomendasDemo.add(
      Encomenda(
        id: id,
        clienteId: _clienteId,
        estado: 'Em avaliação',
        medico: nova.medico,
        paciente: nova.paciente,
        sexoPaciente: nova.sexoPaciente,
        idadePaciente: nova.idadePaciente,
        observacoes: nova.observacoes,
        dataCriacao: DateTime.now(),
        trabalhos: [
          for (final trabalho in nova.trabalhos)
            TrabalhoEncomenda(
              id: 0,
              tipoTrabalho: trabalho.tipo.nome,
              natureza: trabalho.natureza,
              cor: trabalho.cor,
              dentes: trabalho.dentes,
            ),
        ],
      ),
    );
    return id;
  }

  // Comentário da clínica sobre a encomenda (visível para o laboratório).
  Future<void> enviarComentario(int ordemTrabalhoId, String conteudo) async {
    await _esperar();
  }
}
