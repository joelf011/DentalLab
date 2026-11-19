import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/colaborador/inicio/pagina_inicio_colaborador.dart';
import 'package:app_mobile/colaborador/perfil/pagina_perfil.dart';
import 'package:app_mobile/colaborador/trabalhos/pagina_disponiveis.dart';
import 'package:app_mobile/colaborador/trabalhos/pagina_os_meus.dart';
import 'package:app_mobile/colaborador/widget_barra_colaborador.dart';
import 'package:app_mobile/comum/widgets/widget_barra_superior.dart';

// Vista do colaborador (o administrador também entra aqui):
// barra superior + barra inferior com 4 separadores
// (Início, Disponíveis, Os Meus, Perfil).
// "Prazos" não tem separador: abre por cima (Rotas.prazos).
class EcraColaborador extends StatefulWidget {
  const EcraColaborador({super.key});

  @override
  State<EcraColaborador> createState() => _EcraColaboradorState();
}

class _EcraColaboradorState extends State<EcraColaborador> {
  static const _separadorOsMeus = 2;

  int _indiceAtual = 0;

  void _selecionarDestino(int indice) {
    setState(() {
      _indiceAtual = indice;
    });
  }

  void _verOsMeus() {
    _selecionarDestino(_separadorOsMeus);
  }

  void _sair() {
    Sessao.atual = null;
    context.go(Rotas.login);
  }

  @override
  Widget build(BuildContext context) {
    final ecras = [
      PaginaInicioColaborador(aoVerOsMeus: _verOsMeus),
      const PaginaDisponiveis(),
      const PaginaOsMeus(),
      const PaginaPerfil(),
    ];

    return Scaffold(
      appBar: BarraSuperior(
        nome: Sessao.atual!.nome,
        acoes: [TextButton(onPressed: _sair, child: const Text('Sair'))],
      ),
      body: ecras[_indiceAtual],
      bottomNavigationBar: BarraColaborador(
        indiceAtual: _indiceAtual,
        aoSelecionar: _selecionarDestino,
      ),
    );
  }
}
