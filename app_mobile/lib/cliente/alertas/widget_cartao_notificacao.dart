import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/notificacao.dart';
import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';

// Uma notificação: mensagem, encomenda e data. As que estão por ler têm
// fundo dourado claro e um ponto dourado. Ao tocar chama aoAbrir(notificacao).
class CartaoNotificacao extends StatelessWidget {
  const CartaoNotificacao({
    super.key,
    required this.notificacao,
    required this.aoAbrir,
  });

  final Notificacao notificacao;
  final ValueChanged<Notificacao> aoAbrir;

  void _abrir() {
    aoAbrir(notificacao);
  }

  @override
  Widget build(BuildContext context) {
    final lida = notificacao.lida;
    final encomenda = notificacao.ordemTrabalhoId;
    final data = dataCurtaHora(notificacao.dataCriacao);
    return Card(
      color: lida ? CoresApp.superficie : CoresApp.douradoClaro,
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _abrir,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: lida ? CoresApp.fundo : CoresApp.superficie,
                child: Icon(
                  Icons.notifications_none,
                  size: 18,
                  color: lida ? CoresApp.textoSuave : CoresApp.douradoEscuro,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notificacao.mensagem,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: lida ? CoresApp.texto : CoresApp.textoForte,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      encomenda == null
                          ? data
                          : 'Encomenda n.º $encomenda · $data',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CoresApp.textoSuave,
                      ),
                    ),
                  ],
                ),
              ),
              if (!lida)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 6),
                  decoration: const BoxDecoration(
                    color: CoresApp.dourado,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
