import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/app.dart';
import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/alertas/widget_cartao_notificacao.dart';
import 'package:app_mobile/cliente/dados/dados_demo_cliente.dart';
import 'package:app_mobile/cliente/dados/notificacao.dart';

// Testes de Alertas, Conta e Perfil (com os dados de demonstração).
void main() {
  late List<Notificacao> notificacoesIniciais;

  // Os testes marcam notificações como lidas: no fim repõem-se as originais.
  setUp(() {
    Sessao.atual = null;
    rotas.go(Rotas.login);
    notificacoesIniciais = List.of(notificacoesDemo);
  });

  tearDown(() {
    notificacoesDemo
      ..clear()
      ..addAll(notificacoesIniciais);
  });

  Future<void> entrar(WidgetTester tester, String utilizador) async {
    tester.view.physicalSize = const Size(600, 1400);
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

  // O número dentro do sino.
  Finder numeroNoSino(String numero) {
    return find.descendant(of: find.byType(Badge), matching: find.text(numero));
  }

  testWidgets('alertas: sino, marcar todas como lidas', (tester) async {
    await entrar(tester, 'clinica');
    expect(numeroNoSino('2'), findsOneWidget);

    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();
    expect(find.text('2 não lidas'), findsOneWidget);
    expect(find.byType(CartaoNotificacao), findsNWidgets(4));

    await tester.tap(find.text('Marcar todas como lidas'));
    await tester.pumpAndSettle();
    expect(find.text('2 não lidas'), findsNothing);
    expect(numeroNoSino('2'), findsNothing);
  });

  testWidgets('alertas: tocar abre a encomenda e fica lida', (tester) async {
    await entrar(tester, 'clinica');
    await tester.tap(find.text('Alertas'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CartaoNotificacao).first);
    await tester.pumpAndSettle();
    expect(find.text('Encomenda n.º 16'), findsOneWidget);

    await tester.tap(find.byTooltip('Voltar às encomendas'));
    await tester.pumpAndSettle();
    expect(find.text('1 não lida'), findsOneWidget);
    expect(numeroNoSino('1'), findsOneWidget);
  });

  testWidgets('conta: dados da clínica e terminar sessão', (tester) async {
    await entrar(tester, 'clinica');
    await tester.tap(find.text('Conta'));
    await tester.pumpAndSettle();
    expect(find.text('Dados da Clínica'), findsOneWidget);
    expect(find.text('501234567'), findsOneWidget);
    expect(find.text('+351 232 000 111'), findsOneWidget);

    await tester.tap(find.text('Terminar sessão'));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(Sessao.atual, isNull);
  });

  testWidgets('conta: alterar palavra-passe valida e confirma', (tester) async {
    await entrar(tester, 'clinica');
    await tester.tap(find.text('Conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alterar palavra-passe'));
    await tester.pumpAndSettle();

    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'antiga123');
    await tester.enterText(campos.at(1), 'nova12345');
    await tester.enterText(campos.at(2), 'outra1234');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('As palavras-passe não coincidem.'), findsOneWidget);

    await tester.enterText(campos.at(2), 'nova12345');
    await tester.tap(find.text('Guardar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Palavra-passe alterada'), findsOneWidget);
  });

  testWidgets('perfil do colaborador: dados e terminar sessão', (tester) async {
    await entrar(tester, 'colaborador');
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('ana@lcd.pt'), findsOneWidget);
    expect(find.text('AM'), findsOneWidget);

    await tester.tap(find.text('Terminar sessão'));
    await tester.pumpAndSettle();
    expect(find.text('Bem-vindo'), findsOneWidget);
  });
}
