import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/app.dart';

void main() {
  testWidgets('mostra o formulário de início de sessão', (tester) async {
    await tester.pumpWidget(const LabApp());

    expect(find.text('Bem-vindo'), findsOneWidget);
    expect(find.text('Entre na sua conta para continuar.'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
