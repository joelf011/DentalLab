import { useEffect, useMemo, useState } from 'react'
import {
  COLABORADORES,
  TIMELINE_EVENTS,
  addWorkNote,
  assumeWorkStep,
  completeWorkStepDecision,
  getAttachmentsByWorkId,
  getClaimableStep,
  getNotesByWorkId,
  getWorkOrderById,
  subscribeLabData,
  toggleNoteVisibility,
  type WorkOrder,
  type WorkOrderStep,
  type UserRole,
} from '../data'
import {
  Avatar,
  Btn,
  DeadlineBadge,
  ErrorState,
  Field,
  GoldDivider,
  Modal,
  NatureBadge,
  SectionTitle,
  Select,
  STEP_STATUS,
  StatusBadge,
  Textarea,
  VisibilityBadge,
  WarningBanner,
  useToast,
} from '../components/ui'

const COLLABORATOR_FALLBACK_ID = 'col1'

interface Props {
  workId: string
  onBack: () => void
  userRole: UserRole
  collaboratorView?: 'inicio' | 'disponiveis' | 'meus' | 'prazos'
}

function ProcessStep({ step, isLast }: { step: WorkOrderStep; isLast: boolean }) {
  const cfg = STEP_STATUS[step.status]
  const done = step.status === 'concluida'
  const active = step.status === 'em_execucao'
  const standby = step.status === 'standby'

  return (
    <div className="flex gap-4">
      <div className="flex flex-col items-center">
        <div className={`w-7 h-7 rounded-full border-2 flex items-center justify-center flex-shrink-0 text-[11px] font-mono ${cfg.ring}`}>
          {done ? <span className="text-emerald-700 text-xs">✓</span> : standby ? <span className="text-orange-700 text-xs">⊠</span> : active ? <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse" /> : <span className="text-[#6B7280]" />}
        </div>
        {!isLast && <div className={`w-px flex-1 mt-1 ${done ? 'bg-emerald-500/25' : active ? 'bg-amber-400/25' : 'bg-[#E5E7EB]'}`} style={{ minHeight: 24 }} />}
      </div>
      <div className="flex-1 pb-5">
        <div className="flex items-start justify-between gap-2">
          <div>
            <p className={`text-[13px] font-medium ${cfg.color}`}>{step.name}</p>
            {step.collaboratorName && (
              <div className="flex items-center gap-1.5 mt-1">
                <Avatar name={step.collaboratorName} size="xs" />
                <span className="text-[11px] text-[#64748B]">{step.collaboratorName}</span>
              </div>
            )}
          </div>
          <div className="text-right flex-shrink-0">
            {step.startedAt && <p className="text-[10px] font-mono text-[#6B7280]">inicio: {new Date(step.startedAt).toLocaleDateString('pt-PT')}</p>}
            {step.completedAt && <p className="text-[10px] font-mono text-emerald-700/70">fim: {new Date(step.completedAt).toLocaleDateString('pt-PT')}</p>}
          </div>
        </div>
        {step.standbyReason && (
          <div className="mt-2 px-3 py-2 bg-orange-400/8 border border-orange-400/20 rounded-sm">
            <p className="text-[11px] text-orange-700/80 italic">Motivo: {step.standbyReason}</p>
          </div>
        )}
      </div>
    </div>
  )
}

function StepDecisionModal({
  work,
  currentCollaborator,
  onClose,
  onDone,
}: {
  work: WorkOrder
  currentCollaborator: { id: string; name: string }
  onClose: () => void
  onDone: (message: string) => void
}) {
  const [action, setAction] = useState<'advance' | 'clinic_trial' | 'finalize' | 'standby' | ''>('')
  const [assignTo, setAssignTo] = useState(currentCollaborator.id)
  const [standbyReason, setStandbyReason] = useState('')
  const [error, setError] = useState('')

  const currentStepIndex = work.steps.findIndex(step => step.status === 'em_execucao')
  const nextStep = currentStepIndex >= 0 ? work.steps[currentStepIndex + 1] : undefined

  const assignees = COLABORADORES.filter(person => person.role === 'colaborador' || person.role === 'rececionista')
    .map(person => ({ value: person.id, label: person.name }))

  const submit = () => {
    if (!action) {
      setError('Selecione uma opcao para concluir a etapa.')
      return
    }
    if (action === 'advance' && !assignTo) {
      setError('Selecione quem recebe a proxima etapa.')
      return
    }
    if (action === 'standby' && !standbyReason.trim()) {
      setError('A justificacao e obrigatoria para standby.')
      return
    }

    const assignee = COLABORADORES.find(person => person.id === assignTo)

    completeWorkStepDecision({
      workId: work.id,
      collaboratorId: currentCollaborator.id,
      collaboratorName: currentCollaborator.name,
      action,
      assignToId: action === 'advance' ? assignee?.id : undefined,
      assignToName: action === 'advance' ? assignee?.name : undefined,
      standbyReason: action === 'standby' ? standbyReason : undefined,
    })

    const actionLabel: Record<Exclude<typeof action, ''>, string> = {
      advance: 'Etapa concluida e avancada para a proxima etapa.',
      clinic_trial: 'Trabalho enviado para prova clinica.',
      finalize: 'Trabalho finalizado com sucesso.',
      standby: 'Trabalho colocado em standby.',
    }

    onDone(actionLabel[action])
    onClose()
  }

  return (
    <Modal title="Concluir Etapa" subtitle={`${work.ref} · ${work.etapaAtual}`} onClose={onClose} width="max-w-2xl">
      <div className="p-6 space-y-4">
        <button
          onClick={() => { setAction('advance'); setError('') }}
          className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'advance' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
        >
          <p className="text-[13px] font-medium text-[#1F2937]">A. Avancar para Proxima Etapa</p>
          <p className="text-[11px] text-[#64748B] mt-1">
            {nextStep ? `Proxima etapa sequencial: ${nextStep.name}` : 'Sem proxima etapa. O trabalho sera concluido.'}
          </p>
        </button>

        {action === 'advance' && nextStep && (
          <Select label="Atribuir etapa para" value={assignTo} onChange={setAssignTo} options={assignees} required />
        )}

        <button
          onClick={() => { setAction('clinic_trial'); setError('') }}
          className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'clinic_trial' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
        >
          <p className="text-[13px] font-medium text-[#1F2937]">B. Enviar para Prova Clinica</p>
          <p className="text-[11px] text-[#64748B] mt-1">Atualiza o trabalho para aguarda_aprovacao / Em prova.</p>
        </button>

        <button
          onClick={() => { setAction('finalize'); setError('') }}
          className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'finalize' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
        >
          <p className="text-[13px] font-medium text-[#1F2937]">C. Finalizar Trabalho</p>
          <p className="text-[11px] text-[#64748B] mt-1">Marca todas as etapas como concluidas e estado global concluido.</p>
        </button>

        <button
          onClick={() => { setAction('standby'); setError('') }}
          className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'standby' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
        >
          <p className="text-[13px] font-medium text-[#1F2937]">D. Colocar em Standby</p>
          <p className="text-[11px] text-[#64748B] mt-1">Exige justificacao e altera estado para em_standby.</p>
        </button>

        {action === 'standby' && (
          <Textarea
            label="Justificacao de standby"
            value={standbyReason}
            onChange={value => { setStandbyReason(value); setError('') }}
            placeholder="Informe o motivo da pausa..."
            rows={3}
          />
        )}

        {error && <p className="text-[11px] text-red-700">! {error}</p>}

        <div className="flex justify-end gap-2 pt-2">
          <Btn variant="ghost" onClick={onClose}>Cancelar</Btn>
          <Btn variant="primary" onClick={submit}>Confirmar decisao</Btn>
        </div>
      </div>
    </Modal>
  )
}

function NotesSection({
  workId,
  userRole,
  author,
}: {
  workId: string
  userRole: UserRole
  author: string
}) {
  const [content, setContent] = useState('')
  const [visibility, setVisibility] = useState<'interna' | 'cliente'>('interna')
  const [tab, setTab] = useState<'all' | 'interna' | 'cliente'>('all')
  const [refreshTick, setRefreshTick] = useState(0)

  useEffect(() => {
    const unsubscribe = subscribeLabData(() => setRefreshTick(value => value + 1))
    return unsubscribe
  }, [])

  const notes = useMemo(() => getNotesByWorkId(workId), [refreshTick, workId])
  const filtered = tab === 'all' ? notes : notes.filter(note => note.visibility === tab)
  const canToggleVisibility = userRole === 'admin' || userRole === 'rececionista'

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-1 border-b border-[#E5E7EB]">
        {([
          { id: 'all', label: 'Todas', count: notes.length },
          { id: 'interna', label: 'Internas', count: notes.filter(note => note.visibility === 'interna').length },
          { id: 'cliente', label: 'Cliente', count: notes.filter(note => note.visibility === 'cliente').length },
        ] as const).map(item => (
          <button
            key={item.id}
            onClick={() => setTab(item.id)}
            className={`px-3 py-2.5 text-[12px] font-medium border-b-2 transition-colors ${tab === item.id ? 'border-[#C9A227] text-[#8A6F14]' : 'border-transparent text-[#64748B]'}`}
          >
            {item.label}
            <span className="ml-1.5 text-[10px] font-mono opacity-60">{item.count}</span>
          </button>
        ))}
      </div>

      {filtered.length === 0 ? (
        <p className="text-[12px] text-[#6B7280] py-4">Sem notas nesta categoria.</p>
      ) : filtered.map(note => (
        <div key={note.id} className="p-3.5 rounded-sm border border-[#E5E7EB] bg-[#FFFFFF]">
          <div className="flex items-center justify-between gap-2 mb-2">
            <VisibilityBadge
              visibility={note.visibility}
              onChange={canToggleVisibility ? () => toggleNoteVisibility(note.id) : undefined}
            />
            {canToggleVisibility && <span className="text-[9px] text-[#9CA3AF] font-mono">clique para alterar</span>}
          </div>
          <p className="text-[12px] text-[#1F2937] leading-relaxed">{note.content}</p>
          <div className="flex items-center gap-2 mt-2.5">
            <Avatar name={note.author} size="xs" />
            <span className="text-[10px] text-[#64748B] font-mono">
              {note.author} · {new Date(note.date).toLocaleDateString('pt-PT', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
            </span>
          </div>
        </div>
      ))}

      <div className="space-y-2.5 pt-3 border-t border-[#E5E7EB]">
        <Textarea
          value={content}
          onChange={setContent}
          placeholder="Adicionar nota..."
          rows={2}
        />
        <div className="flex items-center justify-between gap-3">
          <div className="flex items-center gap-1.5">
            <span className="text-[10px] text-[#6B7280]">Visibilidade:</span>
            {(['interna', 'cliente'] as const).map(value => (
              <button
                key={value}
                onClick={() => setVisibility(value)}
                className={`text-[10px] font-mono px-2 py-1 rounded-sm border ${visibility === value ? 'border-[#C9A227]/50 text-[#8A6F14] bg-[#C9A227]/10' : 'border-[#E5E7EB] text-[#64748B]'}`}
              >
                {value}
              </button>
            ))}
          </div>
          <Btn
            size="sm"
            variant="primary"
            disabled={!content.trim()}
            onClick={() => {
              addWorkNote({ workId, content, author, visibility })
              setContent('')
            }}
          >
            Guardar nota
          </Btn>
        </div>
      </div>
    </div>
  )
}

function FilesSection({ workId }: { workId: string }) {
  const [refreshTick, setRefreshTick] = useState(0)

  useEffect(() => {
    const unsubscribe = subscribeLabData(() => setRefreshTick(value => value + 1))
    return unsubscribe
  }, [])

  const files = useMemo(() => getAttachmentsByWorkId(workId), [refreshTick, workId])
  const stlFiles = files.filter(file => file.category === 'stl')
  const photos = files.filter(file => file.category === 'foto')
  const docs = files.filter(file => file.category === 'documento')

  return (
    <div className="space-y-6">
      {[{ title: 'Modelos STL', items: stlFiles }, { title: 'Fotografias', items: photos }, { title: 'Documentos', items: docs }].map(section => (
        <div key={section.title}>
          <h4 className="text-[11px] font-mono text-[#64748B] uppercase tracking-wider mb-2">{section.title}</h4>
          {section.items.length === 0 ? (
            <p className="text-[12px] text-[#64748B]">Sem ficheiros nesta categoria.</p>
          ) : (
            <div className="space-y-2">
              {section.items.map(file => (
                <div key={file.id} className="flex items-center gap-3 border border-[#E5E7EB] rounded-sm bg-[#FFFFFF] px-3 py-2.5">
                  <div className="flex-1 min-w-0">
                    <p className="text-[12px] text-[#1F2937] truncate">{file.fileName}</p>
                    <p className="text-[10px] text-[#64748B] font-mono mt-0.5">
                      {file.author} · {new Date(file.uploadedAt).toLocaleDateString('pt-PT', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                      {file.sizeLabel ? ` · ${file.sizeLabel}` : ''}
                    </p>
                  </div>
                  <VisibilityBadge visibility={file.visibility} />
                  <button className="text-[#6B7280] hover:text-[#C9A227] transition-colors text-sm">⤓</button>
                </div>
              ))}
            </div>
          )}
        </div>
      ))}
    </div>
  )
}

export default function TrabalhoDetalhe({ workId, onBack, userRole, collaboratorView }: Props) {
  const [work, setWork] = useState<WorkOrder | null>(() => getWorkOrderById(workId) ?? null)
  const [activeTab, setActiveTab] = useState('processo')
  const [modal, setModal] = useState<'accept' | 'assume' | 'complete' | null>(null)
  const [standbyWarningDismissed, setStandbyWarningDismissed] = useState(false)
  const { show, ToastEl } = useToast()

  const currentCollaborator = useMemo(() => {
    const fallback = COLABORADORES.find(person => person.id === COLLABORATOR_FALLBACK_ID)
    return {
      id: fallback?.id ?? COLLABORATOR_FALLBACK_ID,
      name: fallback?.name ?? 'Ana Martins',
    }
  }, [])

  useEffect(() => {
    const refresh = () => setWork(getWorkOrderById(workId) ?? null)
    refresh()
    const unsubscribe = subscribeLabData(refresh)
    return unsubscribe
  }, [workId])

  if (!work) return <ErrorState message="Trabalho nao encontrado." />

  const days = Math.ceil((new Date(work.prazo).getTime() - Date.now()) / 86400000)
  const isLate = days < 0
  const isInternalManager = userRole === 'admin' || userRole === 'rececionista'
  const collaboratorCanAssume = userRole === 'colaborador' && collaboratorView === 'disponiveis'
  const collaboratorCanComplete = userRole === 'colaborador' && collaboratorView === 'meus'
  const events = TIMELINE_EVENTS.filter(event => event.workId === workId)

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {ToastEl}

      {isLate && (
        <WarningBanner message={`Prazo excedido em ${Math.abs(days)} dias - este trabalho necessita de atencao imediata.`} />
      )}
      {work.status === 'em_standby' && !standbyWarningDismissed && (
        <WarningBanner
          message="Trabalho em standby - aguarda resolucao antes de continuar a producao."
          onDismiss={() => setStandbyWarningDismissed(true)}
        />
      )}

      <div className={`flex-shrink-0 border-b ${isLate ? 'border-b-red-500/40' : 'border-b-[#E5E7EB]'}`}>
        <div className="flex items-center gap-3 px-7 py-3 border-b border-[#E5E7EB]">
          <button onClick={onBack} className="text-[#64748B] hover:text-[#1F2937] transition-colors text-sm flex items-center gap-1">
            ← <span className="text-[12px]">Trabalhos</span>
          </button>
          <span className="text-[#9CA3AF]">/</span>
          <span className="text-[11px] font-mono text-[#C9A227]">{work.ref}</span>
        </div>

        <div className="px-7 py-4 flex items-start gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap mb-1">
              <StatusBadge status={work.status} stage={work.etapaAtual} />
              <NatureBadge natureza={work.natureza} />
              <span className="text-[11px] font-mono text-[#64748B]">{work.tipoName}</span>
            </div>
            <h1 className="text-[20px] font-serif text-[#1F2937] leading-tight mt-1">{work.descricao}</h1>
            <p className="text-[12px] text-[#64748B] mt-1">{work.clienteName} · {work.medico} · Paciente: {work.identificadorPaciente}</p>
          </div>

          <div className="flex items-center gap-2 flex-shrink-0 flex-wrap justify-end">
            <DeadlineBadge prazo={work.prazo} />
            {isInternalManager && work.status !== 'concluido' && (
              <>
                <Btn size="sm" onClick={() => setModal('assume')}>Assumir Etapa</Btn>
                <Btn size="sm" onClick={() => setModal('complete')}>Concluir Etapa</Btn>
              </>
            )}
            {collaboratorCanAssume && work.status !== 'concluido' && (
              <Btn size="sm" onClick={() => setModal('assume')}>Assumir Etapa</Btn>
            )}
            {collaboratorCanComplete && work.status !== 'concluido' && (
              <Btn size="sm" onClick={() => setModal('complete')}>Concluir Etapa</Btn>
            )}
          </div>
        </div>
      </div>

      <div className="flex-1 overflow-hidden flex">
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="flex items-center border-b border-[#E5E7EB] px-7 flex-shrink-0 overflow-x-auto">
            {[
              { id: 'processo', label: 'Processo' },
              { id: 'historico', label: 'Historico' },
              { id: 'notas', label: 'Notas' },
              { id: 'ficheiros', label: 'Ficheiros' },
            ].map(tab => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`px-4 py-3 text-[12px] font-medium whitespace-nowrap border-b-2 transition-colors ${activeTab === tab.id ? 'border-[#C9A227] text-[#C9A227]' : 'border-transparent text-[#64748B] hover:text-[#1F2937]'}`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          <div className="flex-1 overflow-y-auto p-7">
            {activeTab === 'processo' && (
              <div className="max-w-2xl">
                {work.steps.map((step, index) => (
                  <ProcessStep key={step.id} step={step} isLast={index === work.steps.length - 1} />
                ))}
              </div>
            )}

            {activeTab === 'historico' && (
              <div className="max-w-xl">
                {events.length === 0 ? (
                  <p className="text-[12px] text-[#6B7280]">Sem eventos registados.</p>
                ) : events.map((event, index) => (
                  <div key={event.id} className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <div className={`w-2 h-2 rounded-full flex-shrink-0 mt-1.5 ${index === 0 ? 'bg-[#C9A227]' : 'bg-[#9CA3AF]'}`} />
                      {index < events.length - 1 && <div className="w-px flex-1 bg-[#E5E7EB] mt-1" />}
                    </div>
                    <div className="pb-4">
                      <p className="text-[12px] text-[#1F2937]">{event.description}</p>
                      <p className="text-[10px] text-[#64748B] font-mono mt-0.5">
                        {event.actor} · {new Date(event.date).toLocaleDateString('pt-PT', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'notas' && (
              <div className="max-w-xl">
                <NotesSection workId={work.id} userRole={userRole} author={currentCollaborator.name} />
              </div>
            )}

            {activeTab === 'ficheiros' && (
              <div className="max-w-xl">
                <FilesSection workId={work.id} />
              </div>
            )}
          </div>
        </div>

        <div className="w-72 flex-shrink-0 border-l border-[#E5E7EB] overflow-y-auto">
          <div className="p-5 space-y-5">
            <div className="space-y-3">
              <SectionTitle>Dados do Trabalho</SectionTitle>
              <Field label="Cliente" value={work.clienteName} />
              <Field label="Medico responsavel" value={work.medico} />
              <Field label="Requisitado por" value={work.requisitadoPor} />
              <Field label="Paciente anonimo" value={work.identificadorPaciente} mono />
              <Field label="Dentes FDI" value={work.dentes.join(', ')} mono />
            </div>

            <GoldDivider />

            <div className="space-y-3">
              <SectionTitle>Especificacoes</SectionTitle>
              <Field label="Tipo de trabalho" value={work.tipoName} />
              <Field label="Material" value={work.material} />
              <Field label="Cor" value={work.cor} mono />
            </div>

            <GoldDivider />

            <div className="space-y-3">
              <SectionTitle>Responsavel Atual</SectionTitle>
              {work.responsavelName ? (
                <div className="flex items-center gap-2">
                  <Avatar name={work.responsavelName} size="sm" />
                  <div>
                    <p className="text-[12px] text-[#1F2937]">{work.responsavelName}</p>
                    <p className="text-[10px] text-[#64748B] font-mono">Etapa: {work.etapaAtual}</p>
                  </div>
                </div>
              ) : (
                <p className="text-[12px] text-[#6B7280]">Nao atribuido</p>
              )}
            </div>
          </div>
        </div>
      </div>

      {modal === 'assume' && (
        <Modal title="Assumir Etapa" subtitle={work.ref} onClose={() => setModal(null)}>
          <div className="p-6 space-y-4">
            <p className="text-[12px] text-[#475569]">Assuma a proxima etapa pronta do fluxo sequencial.</p>
            <div className="border border-[#E5E7EB] rounded-sm px-4 py-3 bg-[#FFFFFF]">
              <p className="text-[12px] text-[#1F2937]">Etapa disponivel: {getClaimableStep(work)?.name ?? 'Nenhuma etapa disponivel no momento'}</p>
            </div>
            <div className="flex justify-end gap-2">
              <Btn variant="ghost" onClick={() => setModal(null)}>Cancelar</Btn>
              <Btn
                variant="primary"
                disabled={!getClaimableStep(work)}
                onClick={() => {
                  const step = getClaimableStep(work)
                  if (!step) return
                  assumeWorkStep({
                    workId: work.id,
                    stepId: step.id,
                    collaboratorId: currentCollaborator.id,
                    collaboratorName: currentCollaborator.name,
                  })
                  setModal(null)
                  show('Etapa assumida com inicio registado.')
                }}
              >
                Assumir etapa
              </Btn>
            </div>
          </div>
        </Modal>
      )}

      {modal === 'complete' && (
        <StepDecisionModal
          work={work}
          currentCollaborator={currentCollaborator}
          onClose={() => setModal(null)}
          onDone={message => show(message)}
        />
      )}
    </div>
  )
}
