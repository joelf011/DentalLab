// Dados de demonstração da vista do colaborador, no formato das vistas da
// base de dados. Só são usados enquanto configuracao.dart tiver usarDadosDemo = true.
import 'package:app_mobile/colaborador/dados/colaborador.dart';
import 'package:app_mobile/colaborador/dados/trabalho.dart';

DateTime _daquiA(int dias) => DateTime.now().add(Duration(days: dias));

const colaboradoresDemo = [
  Colaborador(
    id: 1,
    nome: 'Catarina Domingos',
    email: 'catarina@lcd.pt',
    cargo: 'Administrador',
  ),
  Colaborador(
    id: 2,
    nome: 'Ana Martins',
    email: 'ana@lcd.pt',
    cargo: 'Colaborador',
  ),
  Colaborador(
    id: 3,
    nome: 'Pedro Santos',
    email: 'pedro@lcd.pt',
    cargo: 'Colaborador',
  ),
  Colaborador(
    id: 4,
    nome: 'Jorge Silva',
    email: 'jorge@lcd.pt',
    cargo: 'Colaborador',
  ),
];

final trabalhosDemo = [
  // Em execução pela Ana (id 2): aparece em "Os Meus".
  Trabalho(
    id: 21,
    ordemTrabalhoId: 12,
    tipoTrabalho: 'Coroa',
    natureza: 'FISICO',
    cor: 'A2',
    dentes: const [15],
    cliente: 'Clínica Dental Horizonte',
    estadoOrdem: 'Em processamento',
    prazoEntrega: _daquiA(2),
    etapas: [
      EtapaTrabalho(
        id: 101,
        nome: 'Gesso',
        ordem: 1,
        responsavelId: 3,
        responsavel: 'Pedro Santos',
        dataInicio: _daquiA(-6),
        dataConclusao: _daquiA(-5),
      ),
      EtapaTrabalho(
        id: 102,
        nome: 'Enceramento',
        ordem: 2,
        responsavelId: 2,
        responsavel: 'Ana Martins',
        dataInicio: _daquiA(-1),
      ),
      const EtapaTrabalho(id: 103, nome: 'Fresagem', ordem: 3),
      const EtapaTrabalho(id: 104, nome: 'Acabamento', ordem: 4),
    ],
  ),
  // Disponível: a ordem foi aceite e ninguém assumiu a primeira etapa.
  Trabalho(
    id: 26,
    ordemTrabalhoId: 16,
    tipoTrabalho: 'Coroa sobre implante',
    natureza: 'DIGITAL',
    cor: 'A1',
    dentes: const [36],
    cliente: 'Clínica Dental Horizonte',
    estadoOrdem: 'Por iniciar',
    prazoEntrega: _daquiA(9),
    etapas: const [
      EtapaTrabalho(id: 105, nome: 'CAD/CAM', ordem: 1),
      EtapaTrabalho(id: 106, nome: 'Sinterização', ordem: 2),
      EtapaTrabalho(id: 107, nome: 'Acabamento', ordem: 3),
    ],
  ),
  // Disponível e urgente: a etapa anterior terminou e a seguinte está livre.
  Trabalho(
    id: 28,
    ordemTrabalhoId: 18,
    tipoTrabalho: 'Goteira',
    natureza: 'FISICO',
    cliente: 'Consultório Dr. Lopes',
    estadoOrdem: 'Em processamento',
    prazoEntrega: _daquiA(1),
    etapas: [
      EtapaTrabalho(
        id: 108,
        nome: 'Gesso',
        ordem: 1,
        responsavelId: 4,
        responsavel: 'Jorge Silva',
        dataInicio: _daquiA(-3),
        dataConclusao: _daquiA(-2),
      ),
      const EtapaTrabalho(id: 109, nome: 'Termoformagem', ordem: 2),
      const EtapaTrabalho(id: 110, nome: 'Polimento', ordem: 3),
    ],
  ),
  // Da Ana, com a ordem em espera e o prazo ultrapassado.
  Trabalho(
    id: 22,
    ordemTrabalhoId: 13,
    tipoTrabalho: 'Prótese Parcial Removível',
    natureza: 'FISICO',
    cor: 'A3',
    dentes: const [14, 15, 16, 17, 24, 25, 26],
    cliente: 'Consultório Dr. Lopes',
    estadoOrdem: 'Em espera',
    prazoEntrega: _daquiA(-1),
    etapas: [
      EtapaTrabalho(
        id: 111,
        nome: 'Gesso',
        ordem: 1,
        responsavelId: 2,
        responsavel: 'Ana Martins',
        dataInicio: _daquiA(-7),
        dataConclusao: _daquiA(-6),
      ),
      EtapaTrabalho(
        id: 112,
        nome: 'Estrutura metálica',
        ordem: 2,
        responsavelId: 2,
        responsavel: 'Ana Martins',
        dataInicio: _daquiA(-5),
      ),
      const EtapaTrabalho(id: 113, nome: 'Montagem de dentes', ordem: 3),
    ],
  ),
  // Concluído.
  Trabalho(
    id: 23,
    ordemTrabalhoId: 14,
    tipoTrabalho: 'Faceta',
    natureza: 'FISICO',
    cor: 'B1',
    dentes: const [11, 12, 21, 22],
    cliente: 'Clínica Dental Horizonte',
    estadoOrdem: 'Concluído',
    prazoEntrega: _daquiA(-2),
    etapas: [
      EtapaTrabalho(
        id: 114,
        nome: 'Enceramento',
        ordem: 1,
        responsavelId: 3,
        responsavel: 'Pedro Santos',
        dataInicio: _daquiA(-15),
        dataConclusao: _daquiA(-10),
      ),
    ],
  ),
];
