import 'package:app_mobile/cliente/dados/encomenda_nova.dart';

// Mantém o preenchimento ao fechar um cartão ou voltar ao primeiro passo.
class RascunhoTrabalho {
  TipoTrabalho? tipo;
  String cor = '';
  String descricao = '';
  List<int> dentes = [];
  final Map<String, String> ficheiros = {};
  final Map<String, String> fotografias = {};

  TrabalhoNovo paraTrabalhoNovo() {
    return TrabalhoNovo(
      tipo: tipo!,
      cor: cor.trim(),
      descricao: descricao.trim(),
      dentes: List.of(dentes),
      ficheiros: ficheiros.keys.toList(),
      fotografias: fotografias.keys.toList(),
    );
  }
}
