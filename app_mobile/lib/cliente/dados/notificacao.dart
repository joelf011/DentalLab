// Uma notificação do sininho (tabela notificacao).
// As mensagens são criadas pelos triggers da base de dados.
class Notificacao {
  const Notificacao({
    required this.id,
    required this.mensagem,
    required this.dataCriacao,
    this.ordemTrabalhoId,
    this.dataLeitura,
  });

  final int id;
  final String mensagem;
  final DateTime dataCriacao;
  final int? ordemTrabalhoId; // encomenda que se abre ao tocar
  final DateTime? dataLeitura;

  bool get lida => dataLeitura != null;
}
