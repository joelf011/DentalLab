import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/app.dart';
import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/inicio/widget_contador.dart';
import 'package:app_mobile/cliente/pedidos/widget_cartao_encomenda.dart';

// Testes das listas: Início e Pedidos da clínica, Início, Os Meus e
// Disponíveis do colaborador (com os dados de demonstração).
void main() {
  setUp(() {
    Sessao.atual = null;
    rotas.go(Rotas.login);
  });

  // Entra com uma conta de demonstração, num ecrã alto para caberem as listas.
  Future<void> entrar(WidgetTester tester, String utilizador) async {
    tester.view.physicalSize = const Size(600, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField).at(0), utilizador);
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Entrar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  // O número mostrado num contador.
  Finder valorDoContador(String texto, String valor) {
    return find.descendant(
      of: find.widgetWithText(Contador, texto),
      matching: find.text(valor),
    );
  }

  // O cartão de encomenda de um paciente.
  Finder cartao(String paciente) =>
      find.widgetWithText(CartaoEncomenda, paciente);

  testWidgets('início da clínica: contadores pelos estados da clínica', (
    tester,
  ) async {
    await entrar(tester, 'clinica');
    expect(valorDoContador('Iniciar', '2'), findsOneWidget);
    expect(valorDoContador('Processamento', '1'), findsOneWidget);
    expect(valorDoContador('Concluído', '1'), findsOneWidget);
  });

  testWidgets('pedidos: filtros rápidos e pesquisa', (tester) async {
    await entrar(tester, 'clinica');
    await tester.tap(find.text('Pedidos'));
    await tester.pumpAndSettle();
    expect(cartao('PAC-0847'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Iniciar'));
    await tester.pumpAndSettle();
    expect(cartao('PAC-0851'), findsOneWidget);
    expect(cartao('PAC-0852'), findsOneWidget);
    expect(cartao('PAC-0847'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.enterText(find.byType(TextField).first, 'PAC-0765');
    await tester.pumpAndSettle();
    expect(cartao('PAC-0765'), findsOneWidget);
    expect(cartao('PAC-0847'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Sem resultados'), findsOneWidget);
  });

  testWidgets('início do colaborador: ativos, em execução e urgentes', (
    tester,
  ) async {
    await entrar(tester, 'colaborador');
    expect(find.text('Olá, Ana Martins'), findsOneWidget);
    expect(valorDoContador('Ativos', '2'), findsOneWidget);
    expect(valorDoContador('Em execução', '1'), findsOneWidget);
    expect(valorDoContador('Urgentes', '3'), findsOneWidget);
  });

  testWidgets('os meus: variante em processamento e cartão normal', (
    tester,
  ) async {
    await entrar(tester, 'colaborador');
    await tester.tap(find.text('Os Meus'));
    await tester.pumpAndSettle();
    expect(find.text('Trabalhos Atribuídos'), findsOneWidget);
    expect(find.text('EM PROCESSAMENTO'), findsOneWidget);
    expect(find.text('Coroa'), findsOneWidget);
    expect(find.text('Prótese Parcial Removível'), findsOneWidget);
    expect(find.text('✓ Concluir Etapa'), findsOneWidget);
  });

  testWidgets('disponíveis: só os trabalhos que ninguém assumiu', (
    tester,
  ) async {
    await entrar(tester, 'colaborador');
    await tester.tap(find.text('Disponíveis'));
    await tester.pumpAndSettle();
    expect(find.text('Trabalhos Disponíveis'), findsOneWidget);
    expect(find.text('Coroa sobre implante'), findsOneWidget);
    expect(find.text('Goteira'), findsOneWidget);
    expect(find.text('Coroa'), findsNothing);
  });
}
