import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/dados_demo_cliente.dart';
import 'package:app_mobile/cliente/detalhe_encomenda/pagina_detalhe_encomenda.dart';
import 'package:app_mobile/colaborador/dados/dados_demo_colaborador.dart';
import 'package:app_mobile/colaborador/detalhe_trabalho/pagina_detalhe_trabalho.dart';

// Testes dos detalhes (trabalho e encomenda) e das janelas do colaborador
// (com os dados de demonstração e a sessão da Ana Martins).
void main() {
  setUp(() {
    Sessao.atual = const Sessao(
      id: 2,
      nome: 'Ana Martins',
      email: 'ana@lcd.pt',
      cargo: 'Colaborador',
      perfil: Perfil.colaborador,
    );
  });

  // Abre o detalhe de um trabalho dos dados de demonstração.
  Future<void> abrir(WidgetTester tester, int trabalhoId) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final trabalho = trabalhosDemo.firstWhere((t) => t.id == trabalhoId);
    await tester.pumpWidget(
      MaterialApp(home: PaginaDetalheTrabalho(trabalho: trabalho)),
    );
  }

  // Escolhe uma opção numa lista (DropdownButtonFormField).
  Future<void> escolher(WidgetTester tester, String atual, String nova) async {
    await tester.tap(find.text(atual).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(nova).last);
    await tester.pumpAndSettle();
  }

  testWidgets('em execução: etapa ativa, etapas do processo e ações', (
    tester,
  ) async {
    await abrir(tester, 21);
    expect(find.text('ETAPA ATIVA'), findsOneWidget);
    expect(find.text('Enceramento'), findsOneWidget);
    expect(find.text('Concluir Etapa'), findsOneWidget);
    expect(find.text('Assumir Etapa'), findsNothing);

    await tester.tap(find.text('Consultar etapas do processo'));
    await tester.pumpAndSettle();
    expect(find.text('Fresagem'), findsOneWidget);
    expect(find.text('Pedro'), findsOneWidget);
    expect(find.text('Por atribuir'), findsNWidgets(2));
  });

  testWidgets('disponível: Assumir Etapa', (tester) async {
    await abrir(tester, 28);
    expect(find.text('Concluir Etapa'), findsNothing);
    await tester.tap(find.text('Assumir Etapa'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Etapa atual iniciada'), findsOneWidget);
  });

  testWidgets('concluir etapa: próxima etapa e colaborador obrigatório', (
    tester,
  ) async {
    await abrir(tester, 21);
    await tester.tap(find.text('Concluir Etapa'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa atual: Enceramento'), findsOneWidget);
    expect(find.text('Próxima Etapa: Fresagem'), findsOneWidget);

    await escolher(tester, 'Deixar livre', 'Atribuir a Outro Colaborador');
    await tester.tap(find.widgetWithText(FilledButton, 'Concluir Etapa').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Selecione o colaborador que receberá a próxima etapa.'),
      findsOneWidget,
    );

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jorge Silva').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Concluir Etapa').last);
    await tester.pumpAndSettle();
    expect(find.text('Etapa atualizada com sucesso'), findsOneWidget);
    expect(find.text('Etapa atual: Enceramento'), findsNothing);
  });

  testWidgets('concluir etapa: standby pede a justificação', (tester) async {
    await abrir(tester, 21);
    await tester.tap(find.text('Concluir Etapa'));
    await tester.pumpAndSettle();
    await escolher(
      tester,
      'Avançar na sequência de produção',
      'Colocar em standby',
    );
    final botao = find.widgetWithText(FilledButton, 'Colocar em standby');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(
      find.text('A justificação é obrigatória para standby.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField).last, 'Falta material');
    await tester.ensureVisible(botao);
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text('Trabalho colocado em standby'), findsOneWidget);
  });

  testWidgets('nota: obrigatória e guardada', (tester) async {
    await abrir(tester, 21);
    await tester.tap(find.text('Nota'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Preencha este campo.'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Verificar a cor');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Nota adicionada'), findsOneWidget);
  });

  testWidgets('standby: justificação obrigatória', (tester) async {
    await abrir(tester, 21);
    await tester.tap(find.text('Standby'));
    await tester.pumpAndSettle();
    expect(find.text('Etapa atual: Enceramento'), findsOneWidget);

    final botao = find.widgetWithText(FilledButton, 'Colocar em standby');
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(
      find.text('A justificação é obrigatória para standby.'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextFormField), 'Aguarda impressão');
    await tester.tap(botao);
    await tester.pumpAndSettle();
    expect(find.text('Trabalho colocado em standby'), findsOneWidget);
  });

  testWidgets('fotografia: câmara, galeria e guardar só com fotografia', (
    tester,
  ) async {
    await abrir(tester, 21);
    await tester.tap(find.text('Foto'));
    await tester.pumpAndSettle();
    expect(find.text('Câmara'), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);
    final guardar = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar'),
    );
    expect(guardar.onPressed, isNull);
  });

  // Num ecrã pequeno, se algum texto não couber o teste falha (overflow).
  testWidgets('telemóvel pequeno: detalhes sem nada cortado', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PaginaDetalheEncomenda(encomenda: encomendasDemo.first),
      ),
    );
    for (final aba in ['Progresso', 'Informação', 'Histórico']) {
      await tester.ensureVisible(find.text(aba));
      await tester.tap(find.text(aba));
      await tester.pumpAndSettle();
    }
    expect(
      find.text('Do primeiro ao mais recente · siga a numeração.'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      MaterialApp(home: PaginaDetalheTrabalho(trabalho: trabalhosDemo.first)),
    );
    await tester.pumpAndSettle();
    expect(find.text('ETAPA ATIVA'), findsOneWidget);
  });
}
