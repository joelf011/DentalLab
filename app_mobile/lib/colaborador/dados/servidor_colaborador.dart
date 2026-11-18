import 'package:app_mobile/colaborador/dados/colaborador.dart';
import 'package:app_mobile/colaborador/dados/dados_demo_colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';
import 'package:app_mobile/configuracao.dart';

// Pedidos de dados da vista do colaborador. O url da API vem no construtor
// e cada método é uma tarefa assíncrona (Future).
// Enquanto usarDadosDemo for true, devolvem os dados de demonstração;
// depois passam a usar http.get / http.post + jsonDecode.
class ServidorColaborador {
  const ServidorColaborador({this.url = urlApi});

  final String url;

  // Simula o tempo de resposta da API.
  Future<void> _esperar() =>
      Future<void>.delayed(const Duration(milliseconds: 300));

  // Trabalhos de todas as ordens em curso, com as suas etapas.
  Future<List<Trabalho>> obterTrabalhos() async {
    await _esperar();
    return trabalhosDemo;
  }

  // Colaboradores ativos, para atribuir a etapa seguinte.
  Future<List<Colaborador>> obterColaboradores() async {
    await _esperar();
    return colaboradoresDemo.where((colaborador) => colaborador.ativo).toList();
  }

  // Assumir a etapa atual: preenche responsavel_id e data_inicio.
  Future<void> assumirEtapa(int etapaTrabalhoId) async {
    await _esperar();
  }

  // Concluir a etapa atual: preenche data_conclusao.
  // atribuicao: livre | eu | outro (com colaboradorId) — responsável da etapa seguinte.
  // destino: avancar | prova (ordem passa a "Em prova").
  Future<void> concluirEtapa(
    int etapaTrabalhoId, {
    required String atribuicao,
    int? colaboradorId,
    String nota = '',
    String destino = 'avancar',
  }) async {
    await _esperar();
  }

  // Colocar a ordem "Em espera": o motivo_espera é obrigatório.
  Future<void> colocarEmEspera(int ordemTrabalhoId, String motivo) async {
    await _esperar();
  }

  // Comentário interno associado ao trabalho (a clínica não o vê).
  Future<void> adicionarNota(int trabalhoId, String conteudo) async {
    await _esperar();
  }

  // Ficheiro do tipo "Fotografia" associado ao trabalho.
  Future<void> adicionarFotografia(int trabalhoId, String caminho) async {
    await _esperar();
  }
}
