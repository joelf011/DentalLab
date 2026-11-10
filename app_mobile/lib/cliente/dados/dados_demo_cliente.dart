// Dados de demonstração da vista da clínica. Só são usados pelo
// ServidorCliente enquanto configuracao.dart tiver usarDadosDemo = true.
import 'package:app_mobile/cliente/dados/clinica.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/encomenda_nova.dart';
import 'package:app_mobile/cliente/dados/notificacao.dart';

// Datas a contar de hoje, para os prazos parecerem sempre reais.
DateTime _daquiA(int dias) => DateTime.now().add(Duration(days: dias));

const clinicasDemo = [
  Clinica(
    id: 'c1',
    nome: 'Clínica Dental Horizonte',
    email: 'geral@horizonte.pt',
    nif: '501234567',
    telefone: '+351 232 000 111',
    morada: 'Rua da Saudade 12, 3500-000 Viseu',
  ),
  Clinica(
    id: 'c2',
    nome: 'Consultório Dr. Lopes',
    email: 'slopesclinica@gmail.com',
    nif: '502345678',
    telefone: '+351 232 000 222',
    morada: 'Avenida Central 45, 3510-000 Viseu',
  ),
];

const tiposTrabalhoDemo = [
  TipoTrabalho(id: 't1', nome: 'Coroa de zircónia', natureza: 'Físico'),
  TipoTrabalho(id: 't2', nome: 'Coroa de feldspato', natureza: 'Físico'),
  TipoTrabalho(id: 't3', nome: 'Ponte', natureza: 'Digital'),
  TipoTrabalho(id: 't4', nome: 'Faceta', natureza: 'Físico'),
  TipoTrabalho(id: 't5', nome: 'Goteira', natureza: 'Físico'),
  TipoTrabalho(id: 't6', nome: 'Prótese Parcial Removível', natureza: 'Físico'),
  TipoTrabalho(id: 't7', nome: 'Coroa sobre implante', natureza: 'Digital'),
];

final encomendasDemo = [
  Encomenda(
    id: 'w1',
    clinicaId: 'c1',
    referencia: 'LCD-2026-0847',
    tipo: 'Coroa de zircónia',
    paciente: '#PAC-0847',
    estado: 'em_producao',
    etapa: 'Enceramento',
    prazo: _daquiA(3),
    medico: 'Dr. Rui Figueiredo',
    material: 'Zircónia',
    cor: 'A2',
    descricao: 'Coroa unitária. Verificar a oclusão cuidadosamente.',
    dentes: const [15],
    etapas: const [
      EtapaEncomenda(nome: 'Receção', concluida: true),
      EtapaEncomenda(nome: 'Análise técnica', concluida: true),
      EtapaEncomenda(nome: 'Enceramento'),
      EtapaEncomenda(nome: 'Fresagem'),
      EtapaEncomenda(nome: 'Acabamento'),
      EtapaEncomenda(nome: 'Controlo de qualidade'),
      EtapaEncomenda(nome: 'Expedição'),
    ],
    eventos: const [
      EventoEncomenda(
        descricao: 'Encomenda recebida',
        autor: 'Laboratório',
        data: '02/11/2026',
      ),
      EventoEncomenda(
        descricao: 'Encomenda encaminhada para produção',
        autor: 'Laboratório',
        data: '02/11/2026',
      ),
      EventoEncomenda(
        descricao: 'Enceramento iniciado',
        autor: 'Laboratório',
        data: '04/11/2026',
      ),
    ],
    mensagens: const [
      MensagemEncomenda(
        autor: 'Laboratório',
        texto: 'Trabalho em execução. O enceramento já foi iniciado.',
        data: '04/11/2026',
      ),
    ],
  ),
  Encomenda(
    id: 'w2',
    clinicaId: 'c2',
    referencia: 'LCD-2026-0848',
    tipo: 'Prótese Parcial Removível',
    paciente: '#PAC-0914',
    estado: 'em_standby',
    etapa: 'Aguarda impressão',
    prazo: _daquiA(6),
    medico: 'Dr. Sérgio Lopes',
    material: 'Cromo-Cobalto',
    cor: 'A3',
    descricao: 'Prótese parcial removível superior. A aguardar nova impressão.',
    dentes: const [14, 15, 16, 17, 24, 25, 26],
    etapas: const [
      EtapaEncomenda(nome: 'Receção', concluida: true),
      EtapaEncomenda(nome: 'Gesso'),
      EtapaEncomenda(nome: 'Estrutura metálica'),
      EtapaEncomenda(nome: 'Montagem de dentes'),
      EtapaEncomenda(nome: 'Expedição'),
    ],
  ),
  Encomenda(
    id: 'w4',
    clinicaId: 'c1',
    referencia: 'LCD-2026-0844',
    tipo: 'Coroa de feldspato',
    paciente: '#PAC-0765',
    estado: 'concluido',
    etapa: 'Entregue',
    prazo: _daquiA(-2),
    medico: 'Dr. Rui Figueiredo',
    material: 'Cerâmica feldspática',
    cor: 'B1',
    descricao: 'Trabalho cerâmico para melhoramento estético.',
    dentes: const [11, 12, 21, 22],
    etapas: const [
      EtapaEncomenda(nome: 'Receção', concluida: true),
      EtapaEncomenda(nome: 'Análise técnica', concluida: true),
      EtapaEncomenda(nome: 'Enceramento', concluida: true),
      EtapaEncomenda(nome: 'Fresagem', concluida: true),
      EtapaEncomenda(nome: 'Acabamento', concluida: true),
      EtapaEncomenda(nome: 'Controlo de qualidade', concluida: true),
      EtapaEncomenda(nome: 'Expedição', concluida: true),
    ],
    eventos: const [
      EventoEncomenda(
        descricao: 'Encomenda recebida',
        autor: 'Laboratório',
        data: '27/10/2026',
      ),
      EventoEncomenda(
        descricao: 'Trabalho concluído',
        autor: 'Laboratório',
        data: '07/11/2026',
      ),
    ],
  ),
  const Encomenda(
    id: 'demo-1',
    clinicaId: 'c1',
    referencia: 'LCD-2026-0851',
    tipo: 'Goteira',
    paciente: '#PAC-0851',
    estado: 'por_receber',
    etapa: 'A aguardar receção',
  ),
  const Encomenda(
    id: 'demo-2',
    clinicaId: 'c1',
    referencia: 'LCD-2026-0852',
    tipo: 'Coroa',
    paciente: '#PAC-0852',
    estado: 'encaminhado',
    etapa: 'Encaminhado',
  ),
  const Encomenda(
    id: 'demo-3',
    clinicaId: 'c1',
    referencia: 'LCD-2026-0853',
    tipo: 'Faceta',
    paciente: '#PAC-0853',
    estado: 'por_receber',
    etapa: 'A aguardar receção',
  ),
];

final notificacoesDemo = [
  Notificacao(
    id: 'n1',
    encomendaId: 'w1',
    tipo: 'aceite',
    mensagem: 'A encomenda #LCD-2026-0847 foi aceite pelo laboratório.',
    data: _daquiA(-1),
  ),
  Notificacao(
    id: 'n2',
    encomendaId: 'w1',
    tipo: 'nota',
    mensagem:
        'O laboratório adicionou uma nova nota à encomenda #LCD-2026-0847.',
    data: _daquiA(-1),
  ),
  Notificacao(
    id: 'n3',
    encomendaId: 'w4',
    tipo: 'concluido',
    mensagem:
        'A encomenda #LCD-2026-0844 está concluída e pronta para levantamento.',
    data: _daquiA(-2),
    lida: true,
  ),
  Notificacao(
    id: 'n4',
    encomendaId: 'w2',
    tipo: 'info',
    mensagem:
        'A encomenda #LCD-2026-0848 foi colocada em standby. '
        'O laboratório aguarda nova impressão.',
    data: _daquiA(-2),
    lida: true,
  ),
];
