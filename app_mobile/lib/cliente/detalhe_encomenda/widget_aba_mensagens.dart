import 'package:flutter/material.dart';

import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

// Aba "Informação": mensagens entre a clínica e o laboratório.
class AbaMensagens extends StatefulWidget {
  const AbaMensagens({super.key, required this.encomenda});

  final Encomenda encomenda;

  @override
  State<AbaMensagens> createState() => _AbaMensagensState();
}

class _AbaMensagensState extends State<AbaMensagens> {
  final _servidor = const ServidorCliente();
  late TextEditingController _controladorMensagem;
  late List<MensagemEncomenda> _mensagens;
  bool _aEnviar = false;

  @override
  void initState() {
    super.initState();
    _controladorMensagem = TextEditingController();
    _mensagens = [...widget.encomenda.mensagens];
  }

  @override
  void dispose() {
    _controladorMensagem.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final texto = _controladorMensagem.text.trim();
    if (texto.isEmpty) return;
    setState(() {
      _aEnviar = true;
    });
    await _servidor.enviarMensagem(widget.encomenda.id, texto);
    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      _mensagens.add(
        MensagemEncomenda(
          autor: 'Clínica',
          texto: texto,
          data: 'Agora',
          daClinica: true,
        ),
      );
      _controladorMensagem.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nota enviada ao laboratório.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Comunicação com o laboratório',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        const Text(
          'Envie informações ou pedidos de alteração relativos a esta encomenda.',
          style: TextStyle(fontSize: 12, color: CoresApp.textoSuave),
        ),
        const SizedBox(height: 16),
        if (_mensagens.isEmpty)
          const Text(
            'Ainda não existem notas. Pode iniciar a conversa abaixo.',
            style: TextStyle(color: CoresApp.textoSuave),
          )
        else
          for (final mensagem in _mensagens)
            _CartaoMensagem(mensagem: mensagem),
        const SizedBox(height: 16),
        CampoTexto(
          etiqueta: 'Adicionar nota',
          controlador: _controladorMensagem,
          dica: 'Escreva a sua mensagem ao laboratório…',
          linhas: 4,
        ),
        const SizedBox(height: 8),
        const Text(
          'Esta nota fica visível para a clínica e para o laboratório.',
          style: TextStyle(fontSize: 11, color: CoresApp.textoSuave),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _aEnviar ? null : _enviar,
          child: const Text('Enviar nota'),
        ),
      ],
    );
  }
}

class _CartaoMensagem extends StatelessWidget {
  const _CartaoMensagem({required this.mensagem});

  final MensagemEncomenda mensagem;

  @override
  Widget build(BuildContext context) {
    final origem = mensagem.daClinica ? 'Clínica' : 'Laboratório';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$origem · ${mensagem.autor}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.douradoEscuro,
                    ),
                  ),
                ),
                Text(
                  mensagem.data,
                  style: const TextStyle(
                    fontSize: 11,
                    color: CoresApp.textoSuave,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(mensagem.texto, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
