// ─── Types ────────────────────────────────────────────────────────────────────

export type UserRole = 'admin' | 'colaborador' | 'rececionista' | 'clinica'
export type WorkStatus = 'por_receber' | 'em_producao' | 'em_standby' | 'concluido' | 'aguarda_aprovacao' | 'encaminhado'
export type WorkNature = 'fisico' | 'digital'
export type StepStatus = 'nao_iniciado' | 'em_execucao' | 'concluida' | 'standby' | 'cancelada'
export type ClientStatus = 'ativo' | 'suspenso' | 'aguarda_validacao'
export type ColabStatus = 'disponivel' | 'ocupado' | 'ausente'

export interface User {
  id: string
  name: string
  email: string
  role: UserRole
  avatar?: string
}

export interface ProcessStep {
  id: string
  name: string
  order: number
}

export interface Process {
  id: string
  name: string
  active: boolean
  steps: ProcessStep[]
  workTypes: string[]
}

export interface WorkType {
  id: string
  name: string
  processId?: string
  nature: WorkNature
}

export interface WorkOrderStep {
  id: string
  stepId: string
  name: string
  status: StepStatus
  collaboratorId?: string
  collaboratorName?: string
  startedAt?: string
  completedAt?: string
  notes?: string
  standbyReason?: string
}

export interface WorkOrder {
  id: string
  ref: string
  clienteId: string
  clienteName: string
  medico: string
  requisitadoPor: string
  identificadorPaciente: string
  sexo: 'M' | 'F'
  idade: number
  tipoId: string
  tipoName: string
  natureza: WorkNature
  material: string
  cor: string
  proximaConsulta: string
  prazo: string
  status: WorkStatus
  etapaAtual: string
  responsavelId?: string
  responsavelName?: string
  dentes: number[]
  descricao: string
  criadoEm: string
  processId: string
  steps: WorkOrderStep[]
}

export interface TimelineEvent {
  id: string
  workId: string
  type: 'criado' | 'aceite' | 'prazo_definido' | 'etapa_iniciada' | 'nota_adicionada' | 'etapa_concluida' | 'encaminhado' | 'standby' | 'retomado' | 'concluido'
  description: string
  actor: string
  date: string
}

export interface InternalNote {
  id: string
  workId: string
  content: string
  author: string
  date: string
  visibility: 'interna' | 'cliente'
}

export interface WorkAttachment {
  id: string
  workId: string
  fileName: string
  category: 'stl' | 'foto' | 'documento'
  uploadedAt: string
  author: string
  visibility: 'interna' | 'cliente'
  sizeLabel?: string
}

export interface Cliente {
  id: string
  name: string
  nif: string
  email: string
  phone: string
  address: string
  status: ClientStatus
  users: number
  activeWorks: number
  registeredAt: string
  doctors: string[]
}

export interface Colaborador {
  id: string
  name: string
  email: string
  role: UserRole
  speciality: string
  status: ColabStatus
  activeWorks: number
  completedThisMonth: number
  joinedAt: string
}

// ─── Mock Data ─────────────────────────────────────────────────────────────────

export const CURRENT_USER: User = {
  id: 'u1',
  name: 'Catarina Domingos',
  email: 'catarina@lcd.pt',
  role: 'admin',
}

export const PROCESSES: Process[] = [
  {
    id: 'p1',
    name: 'Processo Padrão — Prótese Fixa',
    active: true,
    workTypes: ['wt1', 'wt2'],
    steps: [
      { id: 's1', name: 'Receção', order: 1 },
      { id: 's2', name: 'Análise Técnica', order: 2 },
      { id: 's3', name: 'Enceramento', order: 3 },
      { id: 's4', name: 'Fundição / Fresagem', order: 4 },
      { id: 's5', name: 'Acabamento', order: 5 },
      { id: 's6', name: 'Controlo de Qualidade', order: 6 },
      { id: 's7', name: 'Embalagem / Expedição', order: 7 },
    ],
  },
  {
    id: 'p2',
    name: 'Processo Digital — CAD/CAM',
    active: true,
    workTypes: ['wt3'],
    steps: [
      { id: 's8', name: 'Receção de Ficheiros', order: 1 },
      { id: 's9', name: 'Modelação CAD', order: 2 },
      { id: 's10', name: 'Revisão / Aprovação', order: 3 },
      { id: 's11', name: 'Fresagem', order: 4 },
      { id: 's12', name: 'Acabamento Digital', order: 5 },
      { id: 's13', name: 'Expedição', order: 6 },
    ],
  },
  {
    id: 'p3',
    name: 'Processo PPR',
    active: true,
    workTypes: ['wt4'],
    steps: [
      { id: 's14', name: 'Receção', order: 1 },
      { id: 's15', name: 'Gesso', order: 2 },
      { id: 's16', name: 'Estrutura Metálica', order: 3 },
      { id: 's17', name: 'Montagem de Dentes', order: 4 },
      { id: 's18', name: 'Prova', order: 5 },
      { id: 's19', name: 'Acabamento', order: 6 },
      { id: 's20', name: 'Expedição', order: 7 },
    ],
  },
  {
    id: 'p4',
    name: 'Processo Reparação',
    active: false,
    workTypes: ['wt5'],
    steps: [
      { id: 's21', name: 'Receção', order: 1 },
      { id: 's22', name: 'Diagnóstico', order: 2 },
      { id: 's23', name: 'Reparação', order: 3 },
      { id: 's24', name: 'Expedição', order: 4 },
    ],
  },
]

export const WORK_TYPES: WorkType[] = [
  { id: 'wt1', name: 'Coroa', processId: 'p1', nature: 'fisico' },
  { id: 'wt2', name: 'Ponte', processId: 'p1', nature: 'fisico' },
  { id: 'wt3', name: 'Guia Cirúrgico', processId: 'p2', nature: 'digital' },
  { id: 'wt4', name: 'Prótese Parcial Removível', processId: 'p3', nature: 'fisico' },
  { id: 'wt5', name: 'Reparação', processId: 'p4', nature: 'fisico' },
  { id: 'wt6', name: 'Faceta', processId: 'p1', nature: 'fisico' },
  { id: 'wt7', name: 'Goteira', nature: 'fisico' },
  { id: 'wt8', name: 'Planeamento Digital DSD', processId: 'p2', nature: 'digital' },
]

export const CLIENTES: Cliente[] = [
  { id: 'c1', name: 'Clínica Dental Horizonte', nif: '512 345 678', email: 'geral@horizonte.pt', phone: '226 000 111', address: 'Rua das Flores 42, 4050-123 Porto', status: 'ativo', users: 3, activeWorks: 8, registeredAt: '2021-03-10', doctors: ['Dr. Rui Figueiredo', 'Dra. Joana Pires'] },
  { id: 'c2', name: 'Consultório Dr. Lopes', nif: '507 891 234', email: 'slopesclinica@gmail.com', phone: '912 345 678', address: 'Av. da República 18, 4100-150 Porto', status: 'ativo', users: 1, activeWorks: 2, registeredAt: '2022-07-15', doctors: ['Dr. Sérgio Lopes'] },
  { id: 'c3', name: 'Clínica Sorrisão', nif: '509 012 345', email: 'info@sorrisao.pt', phone: '213 456 789', address: 'Rua do Ouro 77, 1100-300 Lisboa', status: 'ativo', users: 4, activeWorks: 3, registeredAt: '2020-01-22', doctors: ['Dra. Mariana Costa', 'Dr. Carlos Neves'] },
  { id: 'c4', name: 'Oral Clinic Porto', nif: '510 234 567', email: 'oralclinicporto@pt', phone: '222 111 000', address: 'Praça Mouzinho 5, 4050-400 Porto', status: 'ativo', users: 2, activeWorks: 4, registeredAt: '2023-09-01', doctors: ['Dra. Sofia Almeida'] },
  { id: 'c5', name: 'Centro Odontológico Lisboa', nif: '511 345 678', email: 'col@cliboa.pt', phone: '213 999 888', address: 'Av. Almirante Reis 200, 1000-050 Lisboa', status: 'suspenso', users: 2, activeWorks: 1, registeredAt: '2021-11-30', doctors: ['Dra. Beatriz Tavares', 'Dr. António Pereira'] },
  { id: 'c6', name: 'SmilePro Dental', nif: '513 456 789', email: 'geral@smilepro.pt', phone: '225 444 333', address: 'Rua de Cedofeita 11, 4050-100 Porto', status: 'aguarda_validacao', users: 0, activeWorks: 0, registeredAt: '2024-12-01', doctors: [] },
]

export const COLABORADORES: Colaborador[] = [
  { id: 'col1', name: 'Ana Martins', email: 'ana@lcd.pt', role: 'colaborador', speciality: 'Ceramista · Estética', status: 'disponivel', activeWorks: 3, completedThisMonth: 12, joinedAt: '2019-04-01' },
  { id: 'col2', name: 'Pedro Santos', email: 'pedro@lcd.pt', role: 'colaborador', speciality: 'Técnico CAD/CAM', status: 'disponivel', activeWorks: 2, completedThisMonth: 9, joinedAt: '2021-06-15' },
  { id: 'col3', name: 'Jorge Vieira', email: 'jorge@lcd.pt', role: 'colaborador', speciality: 'Fundição Metálica', status: 'ocupado', activeWorks: 2, completedThisMonth: 7, joinedAt: '2018-02-20' },
  { id: 'col4', name: 'Marta Oliveira', email: 'marta@lcd.pt', role: 'rececionista', speciality: 'Técnica PPR · Receção', status: 'disponivel', activeWorks: 1, completedThisMonth: 11, joinedAt: '2020-09-01' },
  { id: 'col5', name: 'Ricardo Ferreira', email: 'ricardo@lcd.pt', role: 'colaborador', speciality: 'Auxiliar Técnico', status: 'ausente', activeWorks: 0, completedThisMonth: 5, joinedAt: '2023-03-12' },
  { id: 'col6', name: 'Catarina Domingos', email: 'catarina@lcd.pt', role: 'admin', speciality: 'Administradora', status: 'disponivel', activeWorks: 0, completedThisMonth: 0, joinedAt: '2015-01-01' },
]

export const WORK_ORDERS: WorkOrder[] = [
  {
    id: 'w1', ref: 'LCD-2024-0847', clienteId: 'c1', clienteName: 'Clínica Dental Horizonte',
    medico: 'Dr. Rui Figueiredo', requisitadoPor: 'Enfermeira Carla', identificadorPaciente: '#PAC-0847', sexo: 'M', idade: 54,
    tipoId: 'wt1', tipoName: 'Coroa', natureza: 'fisico', material: 'Cerâmica e-max', cor: 'A2',
    proximaConsulta: '2024-12-19', prazo: '2024-12-18', status: 'em_producao', etapaAtual: 'Enceramento',
    responsavelId: 'col1', responsavelName: 'Ana Martins', dentes: [15], descricao: 'Coroa unitária cerâmica sobre implante. Verificar oclusão cuidadosamente.',
    criadoEm: '2024-12-10', processId: 'p1',
    steps: [
      { id: 'ws1', stepId: 's1', name: 'Receção', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-10T09:00', completedAt: '2024-12-10T09:30' },
      { id: 'ws2', stepId: 's2', name: 'Análise Técnica', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-10T09:30', completedAt: '2024-12-10T11:00' },
      { id: 'ws3', stepId: 's3', name: 'Enceramento', status: 'em_execucao', collaboratorId: 'col1', collaboratorName: 'Ana Martins', startedAt: '2024-12-11T08:00' },
      { id: 'ws4', stepId: 's4', name: 'Fundição / Fresagem', status: 'nao_iniciado' },
      { id: 'ws5', stepId: 's5', name: 'Acabamento', status: 'nao_iniciado' },
      { id: 'ws6', stepId: 's6', name: 'Controlo de Qualidade', status: 'nao_iniciado' },
      { id: 'ws7', stepId: 's7', name: 'Embalagem / Expedição', status: 'nao_iniciado' },
    ],
  },
  {
    id: 'w2', ref: 'LCD-2024-0848', clienteId: 'c2', clienteName: 'Consultório Dr. Lopes',
    medico: 'Dr. Sérgio Lopes', requisitadoPor: 'Dr. Sérgio Lopes', identificadorPaciente: '#PAC-0914', sexo: 'F', idade: 67,
    tipoId: 'wt4', tipoName: 'Prótese Parcial Removível', natureza: 'fisico', material: 'Cromo-Cobalto', cor: 'A3',
    proximaConsulta: '2024-12-23', prazo: '2024-12-22', status: 'em_standby', etapaAtual: 'Aguarda impressão',
    dentes: [14, 15, 16, 17, 24, 25, 26], descricao: 'PPR superior. Aguardar nova impressão do paciente.',
    criadoEm: '2024-12-13', processId: 'p3',
    steps: [
      { id: 'ws8', stepId: 's14', name: 'Receção', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-13T09:00', completedAt: '2024-12-13T09:30' },
      { id: 'ws9', stepId: 's15', name: 'Gesso', status: 'standby', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-13T10:00', standbyReason: 'Impressão com defeito. Cliente a remarcar.' },
      { id: 'ws10', stepId: 's16', name: 'Estrutura Metálica', status: 'nao_iniciado' },
      { id: 'ws11', stepId: 's17', name: 'Montagem de Dentes', status: 'nao_iniciado' },
      { id: 'ws12', stepId: 's18', name: 'Prova', status: 'nao_iniciado' },
      { id: 'ws13', stepId: 's19', name: 'Acabamento', status: 'nao_iniciado' },
      { id: 'ws14', stepId: 's20', name: 'Expedição', status: 'nao_iniciado' },
    ],
  },
  {
    id: 'w3', ref: 'LCD-2024-0849', clienteId: 'c3', clienteName: 'Clínica Sorrisão',
    medico: 'Dra. Mariana Costa', requisitadoPor: 'Dra. Mariana Costa', identificadorPaciente: '#PAC-1092', sexo: 'M', idade: 38,
    tipoId: 'wt8', tipoName: 'Planeamento Digital DSD', natureza: 'digital', material: 'Digital — DICOM/STL', cor: '—',
    proximaConsulta: '2024-12-17', prazo: '2024-12-16', status: 'aguarda_aprovacao', etapaAtual: 'Revisão / Aprovação',
    responsavelId: 'col2', responsavelName: 'Pedro Santos', dentes: [11, 12, 13, 21, 22, 23],
    descricao: 'Design do sorriso digital. Cliente a aguardar aprovação do mockup.',
    criadoEm: '2024-12-10', processId: 'p2',
    steps: [
      { id: 'ws15', stepId: 's8', name: 'Receção de Ficheiros', status: 'concluida', collaboratorId: 'col2', collaboratorName: 'Pedro Santos', startedAt: '2024-12-10T14:00', completedAt: '2024-12-10T15:00' },
      { id: 'ws16', stepId: 's9', name: 'Modelação CAD', status: 'concluida', collaboratorId: 'col2', collaboratorName: 'Pedro Santos', startedAt: '2024-12-11T08:00', completedAt: '2024-12-12T17:00' },
      { id: 'ws17', stepId: 's10', name: 'Revisão / Aprovação', status: 'em_execucao', collaboratorId: 'col2', collaboratorName: 'Pedro Santos', startedAt: '2024-12-13T09:00' },
      { id: 'ws18', stepId: 's11', name: 'Fresagem', status: 'nao_iniciado' },
      { id: 'ws19', stepId: 's12', name: 'Acabamento Digital', status: 'nao_iniciado' },
      { id: 'ws20', stepId: 's13', name: 'Expedição', status: 'nao_iniciado' },
    ],
  },
  {
    id: 'w4', ref: 'LCD-2024-0844', clienteId: 'c1', clienteName: 'Clínica Dental Horizonte',
    medico: 'Dr. Rui Figueiredo', requisitadoPor: 'Enfermeira Carla', identificadorPaciente: '#PAC-0765', sexo: 'F', idade: 45,
    tipoId: 'wt6', tipoName: 'Faceta', natureza: 'fisico', material: 'Cerâmica feldspática', cor: 'B1',
    proximaConsulta: '2024-12-15', prazo: '2024-12-14', status: 'concluido', etapaAtual: 'Entregue',
    responsavelId: 'col1', responsavelName: 'Ana Martins', dentes: [11, 12, 21, 22],
    descricao: 'Facetas cerâmicas para melhoramento estético. Cor B1 máxima claridade.',
    criadoEm: '2024-12-05', processId: 'p1',
    steps: [
      { id: 'ws21', stepId: 's1', name: 'Receção', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-05T09:00', completedAt: '2024-12-05T09:30' },
      { id: 'ws22', stepId: 's2', name: 'Análise Técnica', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-05T09:30', completedAt: '2024-12-05T11:00' },
      { id: 'ws23', stepId: 's3', name: 'Enceramento', status: 'concluida', collaboratorId: 'col1', collaboratorName: 'Ana Martins', startedAt: '2024-12-06T08:00', completedAt: '2024-12-07T16:00' },
      { id: 'ws24', stepId: 's4', name: 'Fundição / Fresagem', status: 'concluida', collaboratorId: 'col3', collaboratorName: 'Jorge Vieira', startedAt: '2024-12-09T08:00', completedAt: '2024-12-10T12:00' },
      { id: 'ws25', stepId: 's5', name: 'Acabamento', status: 'concluida', collaboratorId: 'col1', collaboratorName: 'Ana Martins', startedAt: '2024-12-11T08:00', completedAt: '2024-12-12T16:00' },
      { id: 'ws26', stepId: 's6', name: 'Controlo de Qualidade', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-13T09:00', completedAt: '2024-12-13T10:00' },
      { id: 'ws27', stepId: 's7', name: 'Embalagem / Expedição', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-14T09:00', completedAt: '2024-12-14T10:00' },
    ],
  },
  {
    id: 'w5', ref: 'LCD-2024-0850', clienteId: 'c4', clienteName: 'Oral Clinic Porto',
    medico: 'Dra. Sofia Almeida', requisitadoPor: 'Dra. Sofia Almeida', identificadorPaciente: '#PAC-1138', sexo: 'M', idade: 61,
    tipoId: 'wt2', tipoName: 'Ponte', natureza: 'fisico', material: 'Metal-cerâmica', cor: 'A3',
    proximaConsulta: '2024-12-21', prazo: '2024-12-20', status: 'em_producao', etapaAtual: 'Fundição / Fresagem',
    responsavelId: 'col3', responsavelName: 'Jorge Vieira', dentes: [35, 36, 37],
    descricao: 'Ponte de 3 elementos — 35 a 37. Pilar 35 e 37, pôntico 36.',
    criadoEm: '2024-12-13', processId: 'p1',
    steps: [
      { id: 'ws28', stepId: 's1', name: 'Receção', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-13T09:00', completedAt: '2024-12-13T09:30' },
      { id: 'ws29', stepId: 's2', name: 'Análise Técnica', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-13T09:30', completedAt: '2024-12-13T11:00' },
      { id: 'ws30', stepId: 's3', name: 'Enceramento', status: 'concluida', collaboratorId: 'col1', collaboratorName: 'Ana Martins', startedAt: '2024-12-14T08:00', completedAt: '2024-12-15T16:00' },
      { id: 'ws31', stepId: 's4', name: 'Fundição / Fresagem', status: 'em_execucao', collaboratorId: 'col3', collaboratorName: 'Jorge Vieira', startedAt: '2024-12-16T08:00' },
      { id: 'ws32', stepId: 's5', name: 'Acabamento', status: 'nao_iniciado' },
      { id: 'ws33', stepId: 's6', name: 'Controlo de Qualidade', status: 'nao_iniciado' },
      { id: 'ws34', stepId: 's7', name: 'Embalagem / Expedição', status: 'nao_iniciado' },
    ],
  },
  {
    id: 'w6', ref: 'LCD-2024-0851', clienteId: 'c3', clienteName: 'Clínica Sorrisão',
    medico: 'Dr. Carlos Neves', requisitadoPor: 'Dr. Carlos Neves', identificadorPaciente: '#PAC-1204', sexo: 'F', idade: 29,
    tipoId: 'wt3', tipoName: 'Guia Cirúrgico', natureza: 'digital', material: 'Resina impressa', cor: '—',
    proximaConsulta: '2024-12-25', prazo: '2024-12-24', status: 'encaminhado', etapaAtual: 'Aguarda ficheiros',
    responsavelId: 'col1', responsavelName: 'Ana Martins',
    dentes: [36, 46], descricao: 'Guia cirúrgico para implantologia bilateral. Aguardar DICOM.',
    criadoEm: '2024-12-14', processId: 'p2',
    steps: [
      { id: 'ws35', stepId: 's8', name: 'Receção de Ficheiros', status: 'nao_iniciado' },
      { id: 'ws36', stepId: 's9', name: 'Modelação CAD', status: 'nao_iniciado' },
      { id: 'ws37', stepId: 's10', name: 'Revisão / Aprovação', status: 'nao_iniciado' },
      { id: 'ws38', stepId: 's11', name: 'Fresagem', status: 'nao_iniciado' },
      { id: 'ws39', stepId: 's12', name: 'Acabamento Digital', status: 'nao_iniciado' },
      { id: 'ws40', stepId: 's13', name: 'Expedição', status: 'nao_iniciado' },
    ],
  },
  {
    id: 'w7', ref: 'LCD-2024-0845', clienteId: 'c5', clienteName: 'Centro Odontológico Lisboa',
    medico: 'Dra. Beatriz Tavares', requisitadoPor: 'Dra. Beatriz Tavares', identificadorPaciente: '#PAC-0981', sexo: 'M', idade: 72,
    tipoId: 'wt4', tipoName: 'Prótese Parcial Removível', natureza: 'fisico', material: 'Acrílico', cor: 'A3.5',
    proximaConsulta: '2024-12-20', prazo: '2024-12-19', status: 'em_producao', etapaAtual: 'Montagem de Dentes',
    responsavelId: 'col4', responsavelName: 'Marta Oliveira', dentes: [11, 12, 13, 14, 15, 21, 22, 23, 24],
    descricao: 'PT superior. Rebase total. Verificar dimensão vertical.',
    criadoEm: '2024-12-11', processId: 'p3',
    steps: [
      { id: 'ws41', stepId: 's14', name: 'Receção', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-11T09:00', completedAt: '2024-12-11T09:30' },
      { id: 'ws42', stepId: 's15', name: 'Gesso', status: 'concluida', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-11T10:00', completedAt: '2024-12-12T12:00' },
      { id: 'ws43', stepId: 's16', name: 'Estrutura Metálica', status: 'concluida', collaboratorId: 'col3', collaboratorName: 'Jorge Vieira', startedAt: '2024-12-12T13:00', completedAt: '2024-12-14T16:00' },
      { id: 'ws44', stepId: 's17', name: 'Montagem de Dentes', status: 'em_execucao', collaboratorId: 'col4', collaboratorName: 'Marta Oliveira', startedAt: '2024-12-15T08:00' },
      { id: 'ws45', stepId: 's18', name: 'Prova', status: 'nao_iniciado' },
      { id: 'ws46', stepId: 's19', name: 'Acabamento', status: 'nao_iniciado' },
      { id: 'ws47', stepId: 's20', name: 'Expedição', status: 'nao_iniciado' },
    ],
  },
  {
    id: 'w8', ref: 'LCD-2024-0846', clienteId: 'c4', clienteName: 'Oral Clinic Porto',
    medico: 'Dra. Sofia Almeida', requisitadoPor: 'Rececionista Rita', identificadorPaciente: '#PAC-0816', sexo: 'F', idade: 42,
    tipoId: 'wt1', tipoName: 'Coroa', natureza: 'fisico', material: 'Zircónia', cor: 'A2',
    proximaConsulta: '2024-12-14', prazo: '2024-12-13', status: 'concluido', etapaAtual: 'Entregue',
    responsavelId: 'col2', responsavelName: 'Pedro Santos', dentes: [16, 17],
    descricao: 'Inlays cerâmicos — zircónia monolítica.',
    criadoEm: '2024-12-08', processId: 'p1',
    steps: [],
  },
]

export const TIMELINE_EVENTS: TimelineEvent[] = [
  { id: 'e1', workId: 'w1', type: 'criado', description: 'Trabalho criado', actor: 'Marta Oliveira', date: '2024-12-10T09:00' },
  { id: 'e2', workId: 'w1', type: 'prazo_definido', description: 'Prazo definido: 18 Dez 2024', actor: 'Catarina Domingos', date: '2024-12-10T09:05' },
  { id: 'e3', workId: 'w1', type: 'aceite', description: 'Trabalho aceite e processo atribuído', actor: 'Catarina Domingos', date: '2024-12-10T09:10' },
  { id: 'e4', workId: 'w1', type: 'etapa_iniciada', description: 'Etapa "Receção" iniciada', actor: 'Marta Oliveira', date: '2024-12-10T09:00' },
  { id: 'e5', workId: 'w1', type: 'etapa_concluida', description: 'Etapa "Receção" concluída', actor: 'Marta Oliveira', date: '2024-12-10T09:30' },
  { id: 'e6', workId: 'w1', type: 'etapa_iniciada', description: 'Etapa "Análise Técnica" iniciada', actor: 'Marta Oliveira', date: '2024-12-10T09:30' },
  { id: 'e7', workId: 'w1', type: 'etapa_concluida', description: 'Etapa "Análise Técnica" concluída', actor: 'Marta Oliveira', date: '2024-12-10T11:00' },
  { id: 'e8', workId: 'w1', type: 'encaminhado', description: 'Trabalho encaminhado para Ana Martins', actor: 'Marta Oliveira', date: '2024-12-10T11:05' },
  { id: 'e9', workId: 'w1', type: 'etapa_iniciada', description: 'Etapa "Enceramento" iniciada', actor: 'Ana Martins', date: '2024-12-11T08:00' },
  { id: 'e10', workId: 'w1', type: 'nota_adicionada', description: 'Nota interna adicionada', actor: 'Ana Martins', date: '2024-12-11T10:30' },
]

export const NOTES: InternalNote[] = [
  { id: 'n1', workId: 'w1', content: 'Impressão de qualidade excelente. Sem bolhas ou distorções na zona cervical.', author: 'Marta Oliveira', date: '2024-12-10T09:25', visibility: 'interna' },
  { id: 'n2', workId: 'w1', content: 'Atenção: paciente tem bruxismo severo. Reforçar espessura oclusal mínima 1.5mm.', author: 'Ana Martins', date: '2024-12-11T10:30', visibility: 'interna' },
  { id: 'n3', workId: 'w1', content: 'Trabalho em execução. Previsão de conclusão do enceramento: 12 Dez.', author: 'Ana Martins', date: '2024-12-11T08:05', visibility: 'cliente' },
]

export const WORK_ATTACHMENTS: WorkAttachment[] = [
  { id: 'a1', workId: 'w1', fileName: 'arco_superior.stl', category: 'stl', uploadedAt: '2024-12-10T09:20', author: 'Marta Oliveira', visibility: 'interna', sizeLabel: '4.2 MB' },
  { id: 'a2', workId: 'w1', fileName: 'arco_inferior.stl', category: 'stl', uploadedAt: '2024-12-10T09:20', author: 'Marta Oliveira', visibility: 'interna', sizeLabel: '3.8 MB' },
  { id: 'a3', workId: 'w1', fileName: 'foto_oclusal_01.jpg', category: 'foto', uploadedAt: '2024-12-11T08:10', author: 'Ana Martins', visibility: 'interna', sizeLabel: '2.4 MB' },
  { id: 'a4', workId: 'w1', fileName: 'render_prova_final.jpg', category: 'foto', uploadedAt: '2024-12-12T17:30', author: 'Ana Martins', visibility: 'cliente', sizeLabel: '5.1 MB' },
  { id: 'a5', workId: 'w3', fileName: 'mockup_dsd_v3.pdf', category: 'documento', uploadedAt: '2024-12-13T14:05', author: 'Pedro Santos', visibility: 'cliente', sizeLabel: '1.3 MB' },
  { id: 'a6', workId: 'w3', fileName: 'design_planeamento.stl', category: 'stl', uploadedAt: '2024-12-12T16:20', author: 'Pedro Santos', visibility: 'interna', sizeLabel: '6.7 MB' },
]

type CompletionDecision = 'advance' | 'clinic_trial' | 'finalize' | 'standby'

type LabState = {
  workOrders: WorkOrder[]
  notes: InternalNote[]
  attachments: WorkAttachment[]
}

const LAB_STATE_STORAGE_KEY = 'dentallab.site.state.v1'

function deepClone<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T
}

function defaultLabState(): LabState {
  return {
    workOrders: deepClone(WORK_ORDERS),
    notes: deepClone(NOTES),
    attachments: deepClone(WORK_ATTACHMENTS),
  }
}

function loadLabState(): LabState {
  if (typeof window === 'undefined') return defaultLabState()
  const raw = window.localStorage.getItem(LAB_STATE_STORAGE_KEY)
  if (!raw) return defaultLabState()

  try {
    const parsed = JSON.parse(raw) as Partial<LabState>
    return {
      workOrders: parsed.workOrders && Array.isArray(parsed.workOrders) ? parsed.workOrders : deepClone(WORK_ORDERS),
      notes: parsed.notes && Array.isArray(parsed.notes) ? parsed.notes : deepClone(NOTES),
      attachments: parsed.attachments && Array.isArray(parsed.attachments) ? parsed.attachments : deepClone(WORK_ATTACHMENTS),
    }
  } catch {
    return defaultLabState()
  }
}

let labState: LabState = loadLabState()
const labStateListeners = new Set<() => void>()

function emitLabState() {
  labStateListeners.forEach(listener => listener())
}

function persistLabState() {
  if (typeof window === 'undefined') return
  window.localStorage.setItem(LAB_STATE_STORAGE_KEY, JSON.stringify(labState))
}

function updateLabState(mutator: (state: LabState) => void) {
  mutator(labState)
  persistLabState()
  emitLabState()
}

function nowIso() {
  return new Date().toISOString()
}

function activeStepIndex(work: WorkOrder, stepId?: string) {
  if (stepId) {
    return work.steps.findIndex(step => step.id === stepId)
  }
  return work.steps.findIndex(step => step.status === 'em_execucao')
}

function markStepExecutionOwnership(step: WorkOrderStep, collaboratorId: string, collaboratorName: string) {
  step.status = 'em_execucao'
  step.collaboratorId = collaboratorId
  step.collaboratorName = collaboratorName
  step.startedAt = step.startedAt ?? nowIso()
  step.standbyReason = undefined
}

export function subscribeLabData(listener: () => void) {
  labStateListeners.add(listener)
  return () => {
    labStateListeners.delete(listener)
  }
}

export function getWorkOrders() {
  return labState.workOrders
}

export function getWorkOrderById(workId: string) {
  return labState.workOrders.find(work => work.id === workId)
}

export function getNotesByWorkId(workId: string) {
  return labState.notes.filter(note => note.workId === workId)
}

export function getAttachmentsByWorkId(workId: string) {
  return labState.attachments.filter(file => file.workId === workId)
}

export function getClaimableStep(work: WorkOrder) {
  return work.steps.find((step, index) => {
    const candidate = step.status === 'nao_iniciado' || step.status === 'standby'
    if (!candidate) return false
    if (index === 0) return true
    const previous = work.steps[index - 1]
    return previous.status === 'concluida'
  })
}

export function updateWorkOrder(workId: string, updater: (work: WorkOrder) => void) {
  updateLabState(state => {
    const target = state.workOrders.find(work => work.id === workId)
    if (!target) return
    updater(target)
  })
}

export function assumeWorkStep(params: {
  workId: string
  stepId: string
  collaboratorId: string
  collaboratorName: string
}) {
  updateLabState(state => {
    const work = state.workOrders.find(item => item.id === params.workId)
    if (!work) return

    const step = work.steps.find(item => item.id === params.stepId)
    if (!step) return

    markStepExecutionOwnership(step, params.collaboratorId, params.collaboratorName)
    work.status = 'em_producao'
    work.etapaAtual = step.name
    work.responsavelId = params.collaboratorId
    work.responsavelName = params.collaboratorName
  })
}

export function completeWorkStepDecision(params: {
  workId: string
  collaboratorId: string
  collaboratorName: string
  action: CompletionDecision
  stepId?: string
  assignToId?: string
  assignToName?: string
  standbyReason?: string
}) {
  updateLabState(state => {
    const work = state.workOrders.find(item => item.id === params.workId)
    if (!work) return

    const currentIndex = activeStepIndex(work, params.stepId)
    if (currentIndex < 0) return

    const currentStep = work.steps[currentIndex]
    const timestamp = nowIso()

    if (params.action === 'standby') {
      currentStep.status = 'standby'
      currentStep.standbyReason = params.standbyReason?.trim() || 'Sem motivo indicado'
      work.status = 'em_standby'
      work.etapaAtual = `${currentStep.name} (Standby)`
      work.responsavelId = params.collaboratorId
      work.responsavelName = params.collaboratorName
      return
    }

    currentStep.status = 'concluida'
    currentStep.completedAt = timestamp
    currentStep.collaboratorId = currentStep.collaboratorId ?? params.collaboratorId
    currentStep.collaboratorName = currentStep.collaboratorName ?? params.collaboratorName
    currentStep.startedAt = currentStep.startedAt ?? timestamp
    currentStep.standbyReason = undefined

    if (params.action === 'clinic_trial') {
      work.status = 'aguarda_aprovacao'
      work.etapaAtual = 'Em prova'
      return
    }

    if (params.action === 'finalize') {
      work.steps.forEach(step => {
        if (step.status !== 'concluida') {
          step.status = 'concluida'
          step.startedAt = step.startedAt ?? timestamp
          step.completedAt = step.completedAt ?? timestamp
          step.collaboratorId = step.collaboratorId ?? params.collaboratorId
          step.collaboratorName = step.collaboratorName ?? params.collaboratorName
          step.standbyReason = undefined
        }
      })
      work.status = 'concluido'
      work.etapaAtual = 'Entregue'
      work.responsavelId = params.collaboratorId
      work.responsavelName = params.collaboratorName
      return
    }

    const nextStep = work.steps[currentIndex + 1]
    if (!nextStep) {
      work.status = 'concluido'
      work.etapaAtual = 'Entregue'
      return
    }

    const assigneeId = params.assignToId ?? params.collaboratorId
    const assigneeName = params.assignToName ?? params.collaboratorName
    markStepExecutionOwnership(nextStep, assigneeId, assigneeName)
    work.status = 'em_producao'
    work.etapaAtual = nextStep.name
    work.responsavelId = assigneeId
    work.responsavelName = assigneeName
  })
}

export function addWorkNote(params: {
  workId: string
  content: string
  author: string
  visibility: 'interna' | 'cliente'
}) {
  const trimmed = params.content.trim()
  if (!trimmed) return

  updateLabState(state => {
    state.notes.unshift({
      id: `n${Date.now()}`,
      workId: params.workId,
      content: trimmed,
      author: params.author,
      date: nowIso(),
      visibility: params.visibility,
    })
  })
}

export function toggleNoteVisibility(noteId: string) {
  updateLabState(state => {
    const note = state.notes.find(item => item.id === noteId)
    if (!note) return
    note.visibility = note.visibility === 'interna' ? 'cliente' : 'interna'
  })
}
