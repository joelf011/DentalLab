import 'package:flutter/material.dart';

import 'package:app_mobile/comum/tema/cores_app.dart';

// Círculo com as iniciais de um nome (Conta da clínica e Perfil).
// Exemplo: Avatar(nome: Sessao.atual!.nome)
class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.nome, this.raio = 28});

  final String nome;
  final double raio;

  // "Ana Martins" -> "AM"
  String get _iniciais {
    final palavras = nome
        .trim()
        .split(' ')
        .where((palavra) => palavra.isNotEmpty)
        .toList();
    if (palavras.isEmpty) return '?';
    if (palavras.length == 1) return palavras.first[0].toUpperCase();
    return '${palavras.first[0]}${palavras.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: raio,
      backgroundColor: CoresApp.douradoClaro,
      foregroundColor: CoresApp.douradoEscuro,
      child: Text(
        _iniciais,
        style: TextStyle(fontSize: raio * 0.7, fontWeight: FontWeight.w600),
      ),
    );
  }
}
