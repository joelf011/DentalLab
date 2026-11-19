import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/autenticacao/janela_palavra_passe.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_avatar.dart';
import 'package:app_mobile/comum/widgets/widget_linha_informacao.dart';

// Separador "Perfil" do colaborador (e do administrador):
// nome, cargo e e-mail de quem tem sessão, alterar a palavra-passe
// e terminar sessão.
class PaginaPerfil extends StatefulWidget {
  const PaginaPerfil({super.key});

  @override
  State<PaginaPerfil> createState() => _PaginaPerfilState();
}

class _PaginaPerfilState extends State<PaginaPerfil> {
  void _alterarPalavraPasse() {
    mostrarJanelaPalavraPasse(context);
  }

  void _terminarSessao() {
    Sessao.atual = null;
    context.go(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    final sessao = Sessao.atual!;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Avatar(nome: sessao.nome),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sessao.nome,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          color: CoresApp.textoForte,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sessao.cargo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CoresApp.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                LinhaInformacao(etiqueta: 'E-mail', valor: sessao.email),
                LinhaInformacao(etiqueta: 'Cargo', valor: sessao.cargo),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            title: const Text('Alterar palavra-passe'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _alterarPalavraPasse,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _terminarSessao,
          style: OutlinedButton.styleFrom(
            foregroundColor: CoresApp.erro,
            side: const BorderSide(color: CoresApp.erro),
          ),
          icon: const Icon(Icons.logout),
          label: const Text('Terminar sessão'),
        ),
      ],
    );
  }
}
