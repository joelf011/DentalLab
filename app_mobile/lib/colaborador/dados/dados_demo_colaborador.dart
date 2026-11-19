// Dados de demonstração da vista do colaborador. Só são usados pelo
// ServidorColaborador enquanto configuracao.dart tiver usarDadosDemo = true.
import 'package:app_mobile/colaborador/dados/colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';

DateTime _daquiA(int dias) => DateTime.now().add(Duration(days: dias));

const colaboradoresDemo = [
  Colaborador(id: 's1', nome: 'Ana Martins', email: 'ana@lcd.pt'),
  Colaborador(id: 's2', nome: 'Pedro Santos', email: 'pedro@lcd.pt'),
  Colaborador(id: 's3', nome: 'Jorge Silva', email: 'jorge@lcd.pt'),
  Colaborador(
    id: 's4',
    nome: 'Marta Costa',
    email: 'marta@lcd.pt',
    estado: 'ausente',
  ),
  Colaborador(id: 'admin', nome: 'Catarina Domingos', email: 'catarina@lcd.pt'),
];

final trabalhosDemo = [
  // Em execução pela Ana (s1): aparece em "Os Meus" com Standby / Concluir.
  Trabalho(
    id: 'w1',
    referencia: 'LCD-2026-0847',
    descricao: 'Coroa de zircónia — dente 15',
    clinica: 'Clínica Dental Horizonte',
    tipo: 'Coroa de zircónia',
    prazo: _daquiA(2),
    estado: 'em_producao',
    etapaAtual: 'Enceramento',
    responsavelId: 's1',
    cor: 'A2',
    dentes: const [15],
    etapas: [
      const EtapaTrabalho(
        nome: 'Gesso',
        estado: 'concluida',
        colaboradorId: 's2',
        colaboradorNome: 'Pedro Santos',
      ),
      EtapaTrabalho(
        nome: 'Enceramento',
        estado: 'em_execucao',
        colaboradorId: 's1',
        colaboradorNome: 'Ana Martins',
        iniciadaEm: _daquiA(-1),
      ),
      const EtapaTrabalho(nome: 'Fresagem'),
      const EtapaTrabalho(nome: 'Acabamento'),
    ],
  ),
  // Disponível: a etapa seguinte está livre (aparece em "Disponíveis").
  Trabalho(
    id: 'w3',
    referencia: 'LCD-2026-0849',
    descricao: 'Ponte de 3 elementos',
    clinica: 'Consultório Dr. Lopes',
    tipo: 'Ponte',
    natureza: 'Digital',
    prazo: _daquiA(6),
    estado: 'encaminhado',
    etapaAtual: 'CAD/CAM',
    dentes: const [24, 25, 26],
    etapas: const [
      EtapaTrabalho(nome: 'CAD/CAM'),
      EtapaTrabalho(nome: 'Sinterização'),
      EtapaTrabalho(nome: 'Acabamento'),
    ],
  ),
  // Disponível e urgente.
  Trabalho(
    id: 'w5',
    referencia: 'LCD-2026-0850',
    descricao: 'Goteira de descarga',
    clinica: 'Clínica Dental Horizonte',
    tipo: 'Goteira',
    prazo: _daquiA(1),
    estado: 'em_producao',
    etapaAtual: 'Termoformagem',
    etapas: const [
      EtapaTrabalho(
        nome: 'Gesso',
        estado: 'concluida',
        colaboradorId: 's3',
        colaboradorNome: 'Jorge Silva',
      ),
      EtapaTrabalho(nome: 'Termoformagem'),
      EtapaTrabalho(nome: 'Polimento'),
    ],
  ),
  // Da Ana, em espera (standby) e com o prazo ultrapassado.
  Trabalho(
    id: 'w2',
    referencia: 'LCD-2026-0848',
    descricao: 'Prótese parcial removível superior',
    clinica: 'Consultório Dr. Lopes',
    tipo: 'Prótese Parcial Removível',
    prazo: _daquiA(-1),
    estado: 'em_standby',
    etapaAtual: 'Estrutura metálica',
    responsavelId: 's1',
    dentes: const [14, 15, 16, 17, 24, 25, 26],
    etapas: const [
      EtapaTrabalho(
        nome: 'Gesso',
        estado: 'concluida',
        colaboradorId: 's1',
        colaboradorNome: 'Ana Martins',
      ),
      EtapaTrabalho(
        nome: 'Estrutura metálica',
        estado: 'standby',
        colaboradorId: 's1',
        colaboradorNome: 'Ana Martins',
      ),
      EtapaTrabalho(nome: 'Montagem de dentes'),
    ],
  ),
  // Concluído.
  Trabalho(
    id: 'w4',
    referencia: 'LCD-2026-0844',
    descricao: 'Coroas de feldspato — 4 elementos',
    clinica: 'Clínica Dental Horizonte',
    tipo: 'Coroa de feldspato',
    prazo: _daquiA(-2),
    estado: 'concluido',
    etapaAtual: 'Concluído',
    responsavelId: 's2',
    dentes: const [11, 12, 21, 22],
    etapas: const [
      EtapaTrabalho(nome: 'Enceramento', estado: 'concluida'),
      EtapaTrabalho(nome: 'Acabamento', estado: 'concluida'),
    ],
  ),
];
