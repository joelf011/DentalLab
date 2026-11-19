import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/autenticacao/janela_palavra_passe.dart';
import 'package:app_mobile/cliente/dados/clinica.dart';
import 'package:app_mobile/cliente/dados/servidor_cliente.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_avatar.dart';
import 'package:app_mobile/comum/widgets/widget_linha_informacao.dart';

// Separador "Conta" da clínica: dados da clínica e faturação,
// alterar a palavra-passe, ver as notificações e terminar sessão.
// aoVerAlertas: o EcraCliente muda para o separador Alertas.
class PaginaConta extends StatefulWidget {
  const PaginaConta({super.key, required this.aoVerAlertas});

  final VoidCallback aoVerAlertas;

  @override
  State<PaginaConta> createState() => _PaginaContaState();
}

class _PaginaContaState extends State<PaginaConta> {
  final _servidor = const ServidorCliente();
  late Future<Clinica> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = _servidor.obterClinica();
  }

  void _alterarPalavraPasse() {
    mostrarJanelaPalavraPasse(context);
  }

  void _terminarSessao() {
    Sessao.atual = null;
    context.go(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Clinica>(
      future: _futuro,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _conteudo(snapshot.data!);
        } else if (snapshot.hasError) {
          return const Center(child: Text('Ocorreu um erro'));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _conteudo(Clinica clinica) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Avatar(nome: clinica.nome),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clinica.nome,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      color: CoresApp.textoForte,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    clinica.ativo ? 'Conta ativa' : 'Conta inativa',
                    style: TextStyle(
                      fontSize: 12,
                      color: clinica.ativo ? CoresApp.sucesso : CoresApp.erro,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Card(
          child: ExpansionTile(
            initiallyExpanded: true,
            title: const Text('Dados da Clínica'),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              LinhaInformacao(etiqueta: 'NIF', valor: clinica.nif),
              LinhaInformacao(etiqueta: 'E-mail', valor: clinica.email),
              LinhaInformacao(etiqueta: 'Telefone', valor: clinica.telefone),
              LinhaInformacao(
                etiqueta: 'Morada',
                valor: clinica.moradaFaturacao,
              ),
            ],
          ),
        ),
        Card(
          child: ExpansionTile(
            title: const Text('Faturação'),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              LinhaInformacao(etiqueta: 'NIF', valor: clinica.nif),
              LinhaInformacao(
                etiqueta: 'Morada',
                valor: clinica.moradaFaturacao,
              ),
              const Text(
                'A faturação é gerida pelo laboratório em sistema externo.',
                style: TextStyle(fontSize: 12, color: CoresApp.textoSuave),
              ),
            ],
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
        Card(
          child: ListTile(
            title: const Text('Notificações'),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.aoVerAlertas,
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
        const SizedBox(height: 24),
        const Text(
          'Laboratório Catarina Domingos · v1.0',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: CoresApp.textoSuave),
        ),
      ],
    );
  }
}
