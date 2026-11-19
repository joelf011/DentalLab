import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/comum/tema/cores_app.dart';
import 'package:app_mobile/comum/widgets/widget_logotipo.dart';

// Aviso mostrado depois do registo: a conta aguarda validação do laboratório.
class PaginaPendente extends StatefulWidget {
  const PaginaPendente({super.key});

  @override
  State<PaginaPendente> createState() => _PaginaPendenteState();
}

class _PaginaPendenteState extends State<PaginaPendente> {
  void _voltarAoLogin() {
    context.go(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 384),
              child: Column(
                children: [
                  const Logotipo(largura: 190),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: CoresApp.superficie,
                      border: Border.all(color: CoresApp.dourado),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: CoresApp.douradoClaro,
                          child: Icon(
                            Icons.hourglass_empty,
                            color: CoresApp.douradoEscuro,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Conta a aguardar validação',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 18,
                            color: CoresApp.textoForte,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'O seu registo foi recebido. A conta fica ativa '
                          'depois de ser validada pelo laboratório.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: CoresApp.textoSuave,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _voltarAoLogin,
                    child: const Text('← Voltar ao início de sessão'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
