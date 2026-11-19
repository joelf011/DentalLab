import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/comum/widgets/widget_etiqueta_estado.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_natureza.dart';
import 'package:app_mobile/comum/widgets/widget_etiqueta_prazo.dart';

// Testes das etiquetas de estado, prazo e natureza.
void main() {
  // Mostra um widget sozinho num ecrã.
  Future<void> mostrar(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
  }

  test('a clínica vê os estados agrupados', () {
    expect(textoDoEstado('Em avaliação', paraClinica: true), 'Iniciar');
    expect(textoDoEstado('Por iniciar', paraClinica: true), 'Iniciar');
    expect(textoDoEstado('Em espera', paraClinica: true), 'Processamento');
    expect(textoDoEstado('Em prova', paraClinica: true), 'Processamento');
    expect(textoDoEstado('Entregue', paraClinica: true), 'Concluído');
    expect(textoDoEstado('Rejeitado', paraClinica: true), 'Rejeitado');
  });

  test('o laboratório vê o estado da base de dados', () {
    expect(textoDoEstado('Em espera'), 'Em espera');
  });

  testWidgets('prazo: dias que faltam, atraso e ordem fechada', (tester) async {
    final hoje = DateTime.now();

    await mostrar(
      tester,
      EtiquetaPrazo(
        prazo: hoje.add(const Duration(days: 4)),
        estado: 'Em processamento',
      ),
    );
    expect(find.text('4d'), findsOneWidget);

    await mostrar(
      tester,
      EtiquetaPrazo(
        prazo: hoje.subtract(const Duration(days: 2)),
        estado: 'Em processamento',
      ),
    );
    expect(find.text('2d atraso'), findsOneWidget);

    await mostrar(
      tester,
      EtiquetaPrazo(
        prazo: hoje.subtract(const Duration(days: 2)),
        estado: 'Entregue',
      ),
    );
    expect(find.text('Entregue'), findsOneWidget);
  });

  testWidgets('natureza: FISICO e DIGITAL', (tester) async {
    await mostrar(tester, const EtiquetaNatureza(natureza: 'DIGITAL'));
    expect(find.text('Digital'), findsOneWidget);

    await mostrar(tester, const EtiquetaNatureza(natureza: 'FISICO'));
    expect(find.text('Físico'), findsOneWidget);
  });
}
