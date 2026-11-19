// Dados de demonstração da vista da clínica, no formato das vistas da base
// de dados. Só são usados enquanto configuracao.dart tiver usarDadosDemo = true.
import 'package:app_mobile/cliente/dados/clinica.dart';
import 'package:app_mobile/cliente/dados/encomenda.dart';
import 'package:app_mobile/cliente/dados/encomenda_nova.dart';
import 'package:app_mobile/cliente/dados/notificacao.dart';

// Datas a contar de hoje, para os prazos parecerem sempre reais.
DateTime _daquiA(int dias) => DateTime.now().add(Duration(days: dias));

const clinicasDemo = [
  Clinica(
    id: 1,
    nome: 'Clínica Dental Horizonte',
    nif: '501234567',
    moradaFaturacao: 'Rua da Saudade 12, 3500-000 Viseu',
    email: 'geral@horizonte.pt',
    telefone: '+351 232 000 111',
  ),
  Clinica(
    id: 2,
    nome: 'Consultório Dr. Lopes',
    nif: '502345678',
    moradaFaturacao: 'Avenida Central 45, 3510-000 Viseu',
    email: 'slopesclinica@gmail.com',
    telefone: '+351 232 000 222',
  ),
];

const tiposTrabalhoDemo = [
  TipoTrabalho(id: 1, nome: 'Coroa'),
  TipoTrabalho(id: 2, nome: 'Ponte'),
  TipoTrabalho(id: 3, nome: 'Faceta'),
  TipoTrabalho(id: 4, nome: 'Goteira'),
  TipoTrabalho(id: 5, nome: 'Prótese Parcial Removível'),
  TipoTrabalho(id: 6, nome: 'Coroa sobre implante'),
];

final encomendasDemo = [
  Encomenda(
    id: 12,
    clienteId: 1,
    estado: 'Em processamento',
    medico: 'Dr. Rui Figueiredo',
    paciente: 'PAC-0847',
    sexoPaciente: 'F',
    idadePaciente: 54,
    observacoes: 'Verificar a oclusão cuidadosamente.',
    dataCriacao: _daquiA(-8),
    dataAceitacao: _daquiA(-8),
    dataInicio: _daquiA(-6),
    prazoEntrega: _daquiA(3),
    trabalhos: const [
      TrabalhoEncomenda(
        id: 21,
        tipoTrabalho: 'Coroa',
        natureza: 'FISICO',
        cor: 'A2',
        dentes: [15],
      ),
    ],
    comentarios: [
      Comentario(
        id: 1,
        autor: 'Laboratório',
        conteudo: 'Trabalho em execução. O enceramento já foi iniciado.',
        dataCriacao: _daquiA(-6),
      ),
    ],
  ),
  Encomenda(
    id: 13,
    clienteId: 2,
    estado: 'Em espera',
    medico: 'Dr. Sérgio Lopes',
    paciente: 'PAC-0914',
    sexoPaciente: 'M',
    idadePaciente: 67,
    observacoes: 'Prótese parcial removível superior.',
    motivoEspera: 'A aguardar nova impressão.',
    dataCriacao: _daquiA(-10),
    dataAceitacao: _daquiA(-9),
    dataInicio: _daquiA(-7),
    prazoEntrega: _daquiA(6),
    trabalhos: const [
      TrabalhoEncomenda(
        id: 22,
        tipoTrabalho: 'Prótese Parcial Removível',
        natureza: 'FISICO',
        cor: 'A3',
        dentes: [14, 15, 16, 17, 24, 25, 26],
      ),
    ],
  ),
  Encomenda(
    id: 14,
    clienteId: 1,
    estado: 'Concluído',
    medico: 'Dr. Rui Figueiredo',
    paciente: 'PAC-0765',
    observacoes: 'Trabalho cerâmico para melhoramento estético.',
    dataCriacao: _daquiA(-20),
    dataAceitacao: _daquiA(-19),
    dataInicio: _daquiA(-18),
    dataConclusao: _daquiA(-3),
    prazoEntrega: _daquiA(-2),
    trabalhos: const [
      TrabalhoEncomenda(
        id: 23,
        tipoTrabalho: 'Faceta',
        natureza: 'FISICO',
        cor: 'B1',
        dentes: [11, 12, 21, 22],
      ),
      TrabalhoEncomenda(
        id: 24,
        tipoTrabalho: 'Coroa',
        natureza: 'DIGITAL',
        cor: 'B1',
        dentes: [13],
      ),
    ],
  ),
  Encomenda(
    id: 15,
    clienteId: 1,
    estado: 'Em avaliação',
    medico: 'Dra. Maria Costa',
    paciente: 'PAC-0851',
    dataCriacao: _daquiA(-1),
    trabalhos: const [
      TrabalhoEncomenda(id: 25, tipoTrabalho: 'Goteira', natureza: 'FISICO'),
    ],
  ),
  Encomenda(
    id: 16,
    clienteId: 1,
    estado: 'Por iniciar',
    medico: 'Dr. Rui Figueiredo',
    paciente: 'PAC-0852',
    dataCriacao: _daquiA(-2),
    dataAceitacao: _daquiA(-1),
    prazoEntrega: _daquiA(9),
    trabalhos: const [
      TrabalhoEncomenda(
        id: 26,
        tipoTrabalho: 'Coroa sobre implante',
        natureza: 'DIGITAL',
        cor: 'A1',
        dentes: [36],
      ),
    ],
  ),
  Encomenda(
    id: 17,
    clienteId: 1,
    estado: 'Rejeitado',
    medico: 'Dra. Maria Costa',
    paciente: 'PAC-0853',
    motivoRejeicao: 'A impressão enviada não tem qualidade suficiente.',
    dataCriacao: _daquiA(-4),
    trabalhos: const [
      TrabalhoEncomenda(id: 27, tipoTrabalho: 'Ponte', natureza: 'FISICO'),
    ],
  ),
];

final notificacoesDemo = [
  Notificacao(
    id: 1,
    ordemTrabalhoId: 16,
    mensagem: 'A ordem n.º 16 passou para o estado "Por iniciar".',
    dataCriacao: _daquiA(-1),
  ),
  Notificacao(
    id: 2,
    ordemTrabalhoId: 12,
    mensagem: 'A ordem n.º 12 passou para o estado "Em processamento".',
    dataCriacao: _daquiA(-6),
  ),
  Notificacao(
    id: 3,
    ordemTrabalhoId: 17,
    mensagem: 'A ordem n.º 17 passou para o estado "Rejeitado".',
    dataCriacao: _daquiA(-3),
    dataLeitura: _daquiA(-3),
  ),
  Notificacao(
    id: 4,
    ordemTrabalhoId: 14,
    mensagem: 'A ordem n.º 14 passou para o estado "Concluído".',
    dataCriacao: _daquiA(-3),
    dataLeitura: _daquiA(-2),
  ),
];
