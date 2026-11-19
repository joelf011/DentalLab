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

  // Todos os trabalhos em curso no laboratório.
  Future<List<Trabalho>> obterTrabalhos() async {
    await _esperar();
    return trabalhosDemo;
  }

  // Colaboradores a quem se pode atribuir a próxima etapa (não ausentes).
  Future<List<Colaborador>> obterColaboradores() async {
    await _esperar();
    return colaboradoresDemo
        .where((colaborador) => colaborador.estado != 'ausente')
        .toList();
  }

  // Dados de um colaborador (estado, ...).
  Future<Colaborador?> obterColaborador(String id) async {
    await _esperar();
    for (final colaborador in colaboradoresDemo) {
      if (colaborador.id == id) return colaborador;
    }
    return null;
  }

  // "Assumir Etapa" / "Iniciar Etapa".
  Future<void> assumirEtapa(String trabalhoId) async {
    await _esperar();
  }

  // "Concluir Etapa".
  // atribuicao: livre | eu | outro (com colaboradorId)
  // destino: avancar | prova_clinica | standby
  Future<void> concluirEtapa(
    String trabalhoId, {
    required String atribuicao,
    String? colaboradorId,
    String nota = '',
    String destino = 'avancar',
  }) async {
    await _esperar();
  }

  // "Colocar em standby" (justificação obrigatória).
  Future<void> colocarEmStandby(String trabalhoId, String motivo) async {
    await _esperar();
  }

  // Nota interna (a clínica não a vê).
  Future<void> adicionarNota(String trabalhoId, String texto) async {
    await _esperar();
  }

  // Fotografia do trabalho (caminho do ficheiro).
  Future<void> adicionarFotografia(String trabalhoId, String caminho) async {
    await _esperar();
  }
}
