import 'package:app_mobile/cliente/dados/encomenda_nova.dart';

// Um trabalho a ser preenchido na Nova encomenda.
// Mantém o preenchimento ao fechar um cartão ou voltar ao primeiro passo.
class RascunhoTrabalho {
  TipoTrabalho? tipo;
  String natureza = 'FISICO'; // FISICO | DIGITAL
  String cor = '';
  String descricao = '';
  List<int> dentes = [];
  // Caminho (ou URI na web) e nome apresentado ao utilizador.
  final Map<String, String> ficheiros = {};
  final Map<String, String> fotografias = {};

  TrabalhoNovo paraTrabalhoNovo() {
    final corLimpa = cor.trim();
    return TrabalhoNovo(
      tipo: tipo!,
      natureza: natureza,
      cor: corLimpa.isEmpty ? null : corLimpa,
      dentes: List.of(dentes),
    );
  }
}

// A base de dados guarda as observações, os ficheiros e as fotografias na
// encomenda (ordem_trabalho) e não em cada trabalho: juntam-se os de todos.

// "Trabalho 1 (Coroa): ..." por cada trabalho com descrição (null se nenhum tiver).
String? juntarDescricoes(List<RascunhoTrabalho> trabalhos) {
  final linhas = <String>[];
  for (final (indice, trabalho) in trabalhos.indexed) {
    final descricao = trabalho.descricao.trim();
    if (descricao.isEmpty) continue;
    final tipo = trabalho.tipo?.nome ?? 'sem tipo';
    linhas.add('Trabalho ${indice + 1} ($tipo): $descricao');
  }
  if (linhas.isEmpty) return null;
  return linhas.join('\n');
}

List<String> juntarFicheiros(List<RascunhoTrabalho> trabalhos) {
  return [for (final trabalho in trabalhos) ...trabalho.ficheiros.keys];
}

List<String> juntarFotografias(List<RascunhoTrabalho> trabalhos) {
  return [for (final trabalho in trabalhos) ...trabalho.fotografias.keys];
}
