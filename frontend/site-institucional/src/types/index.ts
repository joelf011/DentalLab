// ==========================================
// 1. PERFIS E UTILIZADORES
// ==========================================
export type UserRole = 'ADMIN' | 'COLABORADOR' | 'RECECIONISTA' | 'CLINICA';

export interface User {
  id: string;
  name: string;
  email: string;
  role: UserRole;
  clinicId?: string; // Preenchido se for cliente/clínica
  avatarUrl?: string;
}

export interface ClientClinic {
  id: string;
  commercialName: string;
  taxNumber: string; // NIF obrigatório
  email: string;
  phoneNumber: string;
  address: string;
  active: boolean;
}

// ==========================================
// 2. PACIENTE (DADOS ESTRITAMENTE ANONIMIZADOS)
// ==========================================
export type PatientGender = 'MASCULINO' | 'FEMININO' | 'OMITIR';

export interface PatientAnonymized {
  identifierCode: string; // Código alfanumérico (ex: #PAC-8041)
  age?: number;           // Opcional se for totalmente anónimo
  gender: PatientGender;
  isFullyAnonymous: boolean;
}

// ==========================================
// 3. ESTADOS E CICLO DE VIDA DO TRABALHO
// ==========================================
// Visão simplificada exposta à Clínica (3 Macro-estados)
export type ClinicMacroState = 'EM_ESPERA' | 'EM_PROCESSAMENTO' | 'CONCLUIDO';

// Visão operacional completa interna do Laboratório
export type LabWorkStatus = 
  | 'POR_RECEBER'
  | 'ACEITE'
  | 'EM_PRODUCAO'
  | 'PROVA_CLINICA'
  | 'EM_STANDBY'
  | 'CONCLUIDO'
  | 'REJEITADO';

// Nomenclatura das etapas técnicas laboratoriais
export type LabTechnicalStep =
  | 'GESSO_MODELACAO'
  | 'IMPRESSAO_3D'
  | 'ARTICULACAO'
  | 'CAD_CAM'
  | 'PESAGEM_PROVA'
  | 'PREPARACAO_PROVA'
  | 'ENVIO_PROVA'
  | 'SINTERIZACAO'
  | 'ACRILIZACAO'
  | 'POLIMENTO'
  | 'GLAZE'
  | 'CIMENTACAO'
  | 'FATURACAO'
  | 'EMBALAMENTO_FINAL';

export interface WorkStepProgress {
  stepId: string;
  stepName: LabTechnicalStep | string;
  assignedCollaboratorId?: string;
  assignedCollaboratorName?: string;
  startedAt?: string;   // ISO Datetime
  completedAt?: string; // ISO Datetime
  status: 'PENDENTE' | 'EM_CURSO' | 'CONCLUIDO' | 'IGNORADO';
  internalNotes?: string; // Oculto da clínica
}

// ==========================================
// 4. SUBTRABALHOS / ITENS DE UMA ENCOMENDA
// ==========================================
export type WorkTypeEnum = 
  | 'COROA_ZIRCONIA'
  | 'GOTEIRA_BRUXISMO'
  | 'GOTEIRA_DESPORTO'
  | 'PROTESE_ESQUELETICA'
  | 'PROTESE_TOTAL'
  | 'PROTESE_HIBRIDA'
  | 'COROA_FELDSPATO'
  | 'OUTRO';

export interface WorkOrderItem {
  itemId: string;
  workType: WorkTypeEnum;
  material: string;             // ex: Zircónia Translúcida, Resina Rígida
  shade?: string;                // Cor VITA (ex: A1, A2, Bleach)
  teeth: number[];              // Sistema FDI (11 a 48) selecionados no odontograma
  nature: 'FISICO' | 'DIGITAL';
  notes?: string;
  steps: WorkStepProgress[];    // Fluxo de etapas deste subtrabalho específico
}

// ==========================================
// 5. ENCOMENDA / ORDEM DE TRABALHO GLOBAL
// ==========================================
export interface WorkOrderFile {
  fileId: string;
  fileName: string;
  fileType: 'STL' | 'PLY' | 'FOTOGRAFIA' | 'DOCUMENTO';
  sizeBytes: number;
  uploadedAt: string;
  isInternalOnly: boolean;      // Se true, oculto da clínica
}

export interface WorkOrder {
  id: string;                   // ex: "CD-2026-089"
  clientClinicId: string;
  clientClinicName: string;
  prescribingDoctor: string;    // String simples (sem tabela de médicos)
  patient: PatientAnonymized;
  items: WorkOrderItem[];       // Permite múltiplos trabalhos numa única encomenda
  files: WorkOrderFile[];
  
  // Controlo de Estados e Prazos
  clinicStatus: ClinicMacroState;
  internalStatus: LabWorkStatus;
  standbyReason?: string;
  
  requestedAppointmentDate?: string; // Data solicitada pela clínica
  confirmedDeadline?: string;        // Definida obrigatoriamente na aceitação
  
  createdAt: string;
  acceptedAt?: string;
  finalizedAt?: string;
  
  isArchived: boolean;
  reopenedDetails?: {
    reopenedAt: string;
    reopenedByAdminName: string;
    justification: string;
    newDeadline: string;
  };
}

// ==========================================
// 6. LOGS DE AUDITORIA (EXCLUSIVO ADMIN)
// ==========================================
export type AuditActionType = 
  | 'CRIAR_ENCOMENDA'
  | 'ACEITAR_ENCOMENDA'
  | 'INICIAR_ETAPA'
  | 'CONCLUIR_ETAPA'
  | 'STANDBY_ETAPA'
  | 'ENVIAR_PROVA'
  | 'REABRIR_ENCOMENDA'
  | 'UPLOAD_FICHEIRO'
  | 'CRIAR_UTILIZADOR';

export interface AuditLogEntry {
  id: string;
  timestamp: string;            // ISO Datetime
  userId: string;
  userName: string;
  userRole: UserRole;
  action: AuditActionType;
  targetEntityId: string;       // ex: "CD-2026-089"
  summary: string;              // ex: "Avançou da etapa CAD/CAM para Sinterização"
}