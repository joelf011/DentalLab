import 'package:flutter/material.dart';

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/comum/formatar_datas.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_campo_texto.dart';

// Aba "Informação": comentários entre a clínica e o laboratório.
class AbaMensagens extends StatefulWidget {
  const AbaMensagens({super.key, required this.encomenda});

  final Encomenda encomenda;

  @override
  State<AbaMensagens> createState() => _AbaMensagensState();
}

class _AbaMensagensState extends State<AbaMensagens> {
  final _servidor = const ServidorCliente();
  late TextEditingController _controladorComentario;
  late List<Comentario> _comentarios;
  bool _aEnviar = false;

  @override
  void initState() {
    super.initState();
    _controladorComentario = TextEditingController();
    _comentarios = [...widget.encomenda.comentarios];
  }

  @override
  void dispose() {
    _controladorComentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final conteudo = _controladorComentario.text.trim();
    if (conteudo.isEmpty) return;
    setState(() {
      _aEnviar = true;
    });
    await _servidor.enviarComentario(widget.encomenda.id, conteudo);
    if (!mounted) return;
    setState(() {
      _aEnviar = false;
      _comentarios.add(
        Comentario(
          id: 0,
          autor: Sessao.atual!.nome,
          conteudo: conteudo,
          dataCriacao: DateTime.now(),
          daClinica: true,
        ),
      );
      _controladorComentario.clear();
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
        if (_comentarios.isEmpty)
          const Text(
            'Ainda não existem notas. Pode iniciar a conversa abaixo.',
            style: TextStyle(color: CoresApp.textoSuave),
          )
        else
          for (final comentario in _comentarios)
            _CartaoComentario(comentario: comentario),
        const SizedBox(height: 16),
        CampoTexto(
          etiqueta: 'Adicionar nota',
          controlador: _controladorComentario,
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

class _CartaoComentario extends StatelessWidget {
  const _CartaoComentario({required this.comentario});

  final Comentario comentario;

  @override
  Widget build(BuildContext context) {
    final origem = comentario.daClinica ? 'Clínica' : 'Laboratório';
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
                    '$origem · ${comentario.autor}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CoresApp.douradoEscuro,
                    ),
                  ),
                ),
                Text(
                  dataHora(comentario.dataCriacao),
                  style: const TextStyle(
                    fontSize: 11,
                    color: CoresApp.textoSuave,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comentario.conteudo, style: const TextStyle(height: 1.5)),
          ],
        ),
      ),
    );
  }
}
