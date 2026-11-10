// Uma notificação do separador Alertas.
class Notificacao {
  const Notificacao({
    required this.id,
    required this.encomendaId,
    required this.tipo,
    required this.mensagem,
    required this.data,
    this.lida = false,
  });

  final String id;
  final String encomendaId; // encomenda que se abre ao tocar
  final String tipo; // aceite | progresso | nota | concluido | info
  final String mensagem;
  final DateTime data;
  final bool lida;
}
