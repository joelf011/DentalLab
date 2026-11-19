import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/app.dart';
import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';

// Testes da base: login e as duas barras inferiores.
// Correr com: flutter test
void main() {
  // As rotas são uma variável global: antes de cada teste
  // volta-se ao login e apaga-se a sessão do teste anterior.
  setUp(() {
    Sessao.atual = null;
    rotas.go(Rotas.login);
  });

  // Escreve o utilizador e a palavra-passe e carrega em "Entrar".
  Future<void> entrar(WidgetTester tester, String utilizador) async {
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField).at(0), utilizador);
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Entrar'));
    // Espera pelo login de demonstração (demora 800 ms).
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  testWidgets('mostra o formulário de início de sessão', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('a clínica vê os 5 separadores', (tester) async {
    await entrar(tester, 'clinica');

    for (final separador in ['Início', 'Pedidos', 'Novo', 'Alertas', 'Conta']) {
      expect(find.text(separador), findsOneWidget);
    }
  });

  testWidgets('o colaborador vê os 4 separadores', (tester) async {
    await entrar(tester, 'colaborador');

    for (final separador in ['Início', 'Disponíveis', 'Os Meus', 'Perfil']) {
      expect(find.text(separador), findsOneWidget);
    }
  });
}
