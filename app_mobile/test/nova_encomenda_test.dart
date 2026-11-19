import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_mobile/app.dart';
import 'package:app_mobile/app_go_router.dart';
import 'package:app_mobile/autenticacao/dados/sessao.dart';
import 'package:app_mobile/cliente/dados/dados_demo_cliente.dart';
import 'package:app_mobile/cliente/nova_encomenda/rascunho_trabalho.dart';
import 'package:app_mobile/cliente/nova_encomenda/widget_formulario_trabalho.dart';
import 'package:app_mobile/comum/widgets/widget_odontograma.dart';

void main() {
  late int numeroEncomendas;

  setUp(() {
    Sessao.atual = null;
    rotas.go(Rotas.login);
    numeroEncomendas = encomendasDemo.length;
  });

  tearDown(() {
    encomendasDemo.removeRange(numeroEncomendas, encomendasDemo.length);
  });

  Future<void> abrirNova(
    WidgetTester tester, {
    bool aPartirDePedidos = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.enterText(find.byType(TextFormField).at(0), 'clinica');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('Entrar'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    if (aPartirDePedidos) {
      await tester.tap(find.text('Pedidos'));
      await tester.pumpAndSettle();
      expect(find.text('Encomendas'), findsOneWidget);
    }
    final entrada = find.text(aPartirDePedidos ? 'Novo' : 'Nova Encomenda');
    await tester.ensureVisible(entrada);
    await tester.tap(entrada);
    await tester.pumpAndSettle();
  }

  Future<void> preencherEncomenda(WidgetTester tester) async {
    await tester.enterText(find.byType(TextFormField).at(0), 'Dra. Sofia');
    await tester.enterText(find.byType(TextFormField).at(1), 'PAC-TESTE');
    await tester.enterText(find.byType(TextFormField).at(2), '0');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }

  Future<void> escolherTipo(
    WidgetTester tester,
    int indice,
    String nome,
  ) async {
    final campo = find.byType(DropdownButtonFormField<int>).at(indice);
    await tester.ensureVisible(campo);
    await tester.tap(campo);
    await tester.pumpAndSettle();
    await tester.tap(find.text(nome).last);
    await tester.pumpAndSettle();
  }

  testWidgets('valida dados obrigatórios e idade sem avançar', (tester) async {
    await abrirNova(tester);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Preencha este campo.'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), 'Dra. Sofia');
    await tester.enterText(find.byType(TextFormField).at(1), 'PAC-TESTE');
    for (final idade in ['-1', '121', '2.5', 'abc']) {
      await tester.enterText(find.byType(TextFormField).at(2), idade);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Use uma idade de 0 a 120.'), findsOneWidget);
      expect(find.text('PASSO 1 DE 2'), findsOneWidget);
    }
  });

  testWidgets('cria encomenda com dois trabalhos e mostra-a nos Pedidos', (
    tester,
  ) async {
    await abrirNova(tester);
    await preencherEncomenda(tester);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Enviar Encomenda · 1 trabalho'),
          )
          .onPressed,
      isNull,
    );
    await escolherTipo(tester, 0, 'Coroa');
    await tester.tap(find.text('Odontograma · 0 selecionados'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('11'));
    await tester.tap(find.text('11'));
    await tester.pumpAndSettle();
    final adicionar = find.text('Adicionar trabalho');
    await tester.ensureVisible(adicionar);
    await tester.tap(adicionar);
    await tester.pumpAndSettle();
    expect(find.byType(FormularioTrabalho), findsNWidgets(2));
    await escolherTipo(tester, 1, 'Ponte');
    await tester.tap(find.text('Enviar Encomenda · 2 trabalhos'));
    await tester.pumpAndSettle();
    expect(find.text('Encomenda enviada'), findsOneWidget);
    expect(find.text('0 anos'), findsOneWidget);
    expect(find.text('1. Coroa — 1 dente'), findsOneWidget);
    expect(find.text('2. Ponte — 0 dentes'), findsOneWidget);
    expect(encomendasDemo.length, numeroEncomendas + 1);
    await tester.ensureVisible(find.text('Ver Encomendas'));
    await tester.tap(find.text('Ver Encomendas'));
    await tester.pumpAndSettle();
    expect(find.text('Encomendas'), findsOneWidget);
    final paciente = find.text('PAC-TESTE');
    // A lista dos Pedidos é o primeiro Scrollable (a pesquisa tem outro).
    await tester.scrollUntilVisible(
      paciente,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(paciente, findsOneWidget);
  });

  testWidgets('atualiza Pedidos quando Novo abre a partir desse separador', (
    tester,
  ) async {
    await abrirNova(tester, aPartirDePedidos: true);
    await preencherEncomenda(tester);
    await escolherTipo(tester, 0, 'Ponte');
    await tester.tap(find.text('Enviar Encomenda · 1 trabalho'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Ver Encomendas'));
    await tester.tap(find.text('Ver Encomendas'));
    await tester.pumpAndSettle();

    final paciente = find.text('PAC-TESTE');
    // A lista dos Pedidos é o primeiro Scrollable (a pesquisa tem outro).
    await tester.scrollUntilVisible(
      paciente,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(paciente, findsOneWidget);
  });

  testWidgets(
    'preserva o trabalho ao voltar e repõe um vazio ao remover o último',
    (tester) async {
      await abrirNova(tester);
      await preencherEncomenda(tester);
      await escolherTipo(tester, 0, 'Ponte');
      await tester.enterText(find.byType(TextFormField).first, 'A2');
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Dra. Sofia'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('A2'), findsOneWidget);
      await tester.tap(find.text('Remover'));
      await tester.pumpAndSettle();
      expect(find.byType(FormularioTrabalho), findsOneWidget);
      expect(find.text('A2'), findsNothing);
      expect(find.text('TRABALHO 1'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(
                FilledButton,
                'Enviar Encomenda · 1 trabalho',
              ),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets('cancelar não cria encomendas', (tester) async {
    await abrirNova(tester);
    await preencherEncomenda(tester);
    await tester.tap(find.byTooltip('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.text('PASSO 2 DE 2'), findsNothing);
    expect(find.text('Novo'), findsOneWidget);
    expect(encomendasDemo.length, numeroEncomendas);
  });

  testWidgets('nova encomenda limpa os campos depois do envio', (tester) async {
    await abrirNova(tester);
    await preencherEncomenda(tester);
    await escolherTipo(tester, 0, 'Ponte');
    await tester.tap(find.text('Enviar Encomenda · 1 trabalho'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Nova Encomenda'));
    await tester.tap(find.text('Nova Encomenda'));
    await tester.pumpAndSettle();
    expect(find.text('PASSO 1 DE 2'), findsOneWidget);
    for (final campo in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(campo.controller!.text, isEmpty);
    }
    expect(encomendasDemo.length, numeroEncomendas + 1);
  });

  testWidgets('odontograma seleciona os 32 dentes, limpa e respeita leitura', (
    tester,
  ) async {
    var selecionados = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, atualizar) => Odontograma(
              selecionados: selecionados,
              aoMudar: (dentes) => atualizar(() => selecionados = dentes),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Selecionar todos'));
    await tester.pump();
    expect(selecionados.toSet().length, 32);
    await tester.tap(find.text('11'));
    await tester.pump();
    expect(selecionados, isNot(contains(11)));
    await tester.tap(find.text('Limpar seleção'));
    await tester.pump();
    expect(selecionados, isEmpty);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Odontograma(selecionados: [11, 21])),
      ),
    );
    expect(find.text('Selecionar todos'), findsNothing);
    expect(find.text('Limpar seleção'), findsNothing);
    expect(find.text('Selecionados: 11, 21'), findsOneWidget);
    await tester.tap(find.text('11'));
    await tester.pump();
    expect(find.text('Selecionados: 11, 21'), findsOneWidget);
  });

  test('rascunho entrega os dados do trabalho e da encomenda', () {
    final trabalho = RascunhoTrabalho()
      ..tipo = tiposTrabalhoDemo.first
      ..natureza = 'DIGITAL'
      ..cor = ' A2 '
      ..descricao = ' Indicações clínicas '
      ..dentes = [11, 21];
    trabalho.ficheiros['blob:stl'] = 'digital.stl';
    trabalho.fotografias['blob:foto'] = 'clinica.jpg';
    final novo = trabalho.paraTrabalhoNovo();
    expect(novo.natureza, 'DIGITAL');
    expect(novo.cor, 'A2');
    expect(novo.dentes, [11, 21]);
    trabalho.dentes.clear();
    expect(novo.dentes, [11, 21]);

    final semDados = RascunhoTrabalho()..tipo = tiposTrabalhoDemo.last;
    expect(semDados.paraTrabalhoNovo().cor, isNull);
    expect(
      juntarDescricoes([trabalho, semDados]),
      'Trabalho 1 (Coroa): Indicações clínicas',
    );
    expect(juntarDescricoes([semDados]), isNull);
    expect(juntarFicheiros([trabalho, semDados]), ['blob:stl']);
    expect(juntarFotografias([trabalho, semDados]), ['blob:foto']);
  });
}
