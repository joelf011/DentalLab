export const LAB_PROCESSES = [
  {
    id: 'p1',
    name: 'Prótese Unitária',
    active: true,
    steps: [
      { id: 's1', name: 'Receção', order: 1 },
      { id: 's2', name: 'Análise Técnica', order: 2 },
      { id: 's3', name: 'Enceramento', order: 3 },
      { id: 's4', name: 'Fundição / Fresagem', order: 4 },
      { id: 's5', name: 'Acabamento', order: 5 },
      { id: 's6', name: 'Controlo de Qualidade', order: 6 },
      { id: 's7', name: 'Embalagem / Expedição', order: 7 },
    ],
    workTypes: ['wt1', 'wt2', 'wt5', 'wt6'],
  },
  {
    id: 'p2',
    name: 'Digital / CAD-CAM',
    active: true,
    steps: [
      { id: 's8', name: 'Receção de Ficheiros', order: 1 },
      { id: 's9', name: 'Modelação CAD', order: 2 },
      { id: 's10', name: 'Revisão / Aprovação', order: 3 },
      { id: 's11', name: 'Fresagem', order: 4 },
      { id: 's12', name: 'Acabamento Digital', order: 5 },
      { id: 's13', name: 'Expedição', order: 6 },
    ],
    workTypes: ['wt3', 'wt8', 'wt9'],
  },
  {
    id: 'p3',
    name: 'Prótese Removível',
    active: true,
    steps: [
      { id: 's14', name: 'Receção', order: 1 },
      { id: 's15', name: 'Gesso', order: 2 },
      { id: 's16', name: 'Estrutura Metálica', order: 3 },
      { id: 's17', name: 'Montagem de Dentes', order: 4 },
      { id: 's18', name: 'Prova', order: 5 },
      { id: 's19', name: 'Acabamento', order: 6 },
      { id: 's20', name: 'Expedição', order: 7 },
    ],
    workTypes: ['wt4', 'wt7'],
  },
] as const

export const LAB_WORK_TYPES = [
  { id: 'wt1', name: 'Coroa', nature: 'fisico' },
  { id: 'wt2', name: 'Ponte', nature: 'fisico' },
  { id: 'wt3', name: 'Guia Cirúrgico', nature: 'digital' },
  { id: 'wt4', name: 'Prótese Parcial Removível', nature: 'fisico' },
  { id: 'wt5', name: 'Faceta', nature: 'fisico' },
  { id: 'wt6', name: 'Onlay / Inlay', nature: 'fisico' },
  { id: 'wt7', name: 'Prótese Total', nature: 'fisico' },
  { id: 'wt8', name: 'Planeamento Digital DSD', nature: 'digital' },
  { id: 'wt9', name: 'Mock-up Digital', nature: 'digital' },
] as const

export function alignLaboratoryWork<
  T extends { ref?: string; steps?: unknown[] },
>(work: T): T {
  return {
    ...work,
    ref: work.ref ?? 'LCD-0000',
    steps: work.steps ?? [],
  }
}

export function alignLaboratoryDemoText(
  notes: Array<{ id?: string }> = [],
  events: Array<{ id?: string }> = [],
) {
  return { notes, events }
}
