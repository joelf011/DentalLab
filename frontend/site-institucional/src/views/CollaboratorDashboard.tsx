import { useEffect, useMemo, useState } from 'react'
import type { User, WorkOrder } from '../data'
import {
  COLABORADORES,
  assumeWorkStep,
  completeWorkStepDecision,
  getClaimableStep,
  getWorkOrders,
  subscribeLabData,
} from '../data'
import { Btn, DeadlineBadge, Modal, NatureBadge, Select, StatusBadge, useToast } from '../components/ui'

export type CollaboratorView = 'inicio' | 'disponiveis' | 'meus' | 'prazos'

type CompletionAction = 'advance' | 'clinic_trial' | 'finalize' | 'standby'

const SECTION_TITLES: Record<CollaboratorView, string> = {
  inicio: 'Prioridades e Urgencias',
  disponiveis: 'Fila Disponivel',
  meus: 'Minhas Tarefas',
  prazos: 'Gestao de Prazos',
}

interface CollaboratorDashboardProps {
  user: User
  activeView: CollaboratorView
  onViewChange: (view: CollaboratorView) => void
  onSelectWork: (id: string) => void
}

function formatElapsed(startedAt?: string) {
  if (!startedAt) return 'Inicio nao registado'
  const elapsedMs = Date.now() - new Date(startedAt).getTime()
  if (elapsedMs < 3600000) {
    const minutes = Math.max(1, Math.floor(elapsedMs / 60000))
    return `${minutes} min em execucao`
  }
  const hours = Math.floor(elapsedMs / 3600000)
  return `${hours} h em execucao`
}

function DaysBadge({ prazo }: { prazo: string }) {
  const days = Math.ceil((new Date(prazo).getTime() - Date.now()) / 86400000)
  const overdue = days < 0
  const soon = days >= 0 && days <= 2
  const color = overdue ? 'bg-red-50 text-red-800 border-red-200' : soon ? 'bg-amber-50 text-amber-800 border-amber-200' : 'bg-slate-100 text-slate-700 border-slate-200'
  return (
    <span className={`inline-flex items-center px-2 py-1 text-[10px] font-mono border rounded-md ${color}`}>
      {overdue ? `${Math.abs(days)}d atraso` : `${days}d`}
    </span>
  )
}

function CompleteStepModal({
  work,
  collaboratorId,
  collaboratorName,
  onClose,
  onDone,
}: {
  work: WorkOrder
  collaboratorId: string
  collaboratorName: string
  onClose: () => void
  onDone: (message: string) => void
}) {
  const [action, setAction] = useState<CompletionAction | ''>('')
  const [assignToId, setAssignToId] = useState(collaboratorId)
  const [standbyReason, setStandbyReason] = useState('')
  const [error, setError] = useState('')

  const currentStepIndex = work.steps.findIndex(step => step.status === 'em_execucao')
  const nextStep = currentStepIndex >= 0 ? work.steps[currentStepIndex + 1] : undefined
  const assigneeOptions = COLABORADORES.filter(person => person.role === 'colaborador' || person.role === 'rececionista')
    .map(person => ({ value: person.id, label: person.name }))

  const submit = () => {
    if (!action) {
      setError('Selecione uma decisao para concluir a etapa.')
      return
    }
    if (action === 'advance' && !assignToId) {
      setError('Selecione o colaborador da proxima etapa.')
      return
    }
    if (action === 'standby' && !standbyReason.trim()) {
      setError('A justificacao de standby e obrigatoria.')
      return
    }

    const assignee = COLABORADORES.find(person => person.id === assignToId)

    completeWorkStepDecision({
      workId: work.id,
      collaboratorId,
      collaboratorName,
      action,
      assignToId: action === 'advance' ? assignee?.id : undefined,
      assignToName: action === 'advance' ? assignee?.name : undefined,
      standbyReason: action === 'standby' ? standbyReason : undefined,
    })

    const messages: Record<CompletionAction, string> = {
      advance: 'Etapa concluida e avancada para a proxima etapa.',
      clinic_trial: 'Trabalho enviado para prova clinica.',
      finalize: 'Trabalho finalizado com sucesso.',
      standby: 'Trabalho colocado em standby.',
    }
    onDone(messages[action])
    onClose()
  }

  return (
    <Modal title="Concluir Etapa" subtitle={`${work.ref} · ${work.etapaAtual}`} onClose={onClose} width="max-w-2xl">
      <div className="p-6 space-y-4">
        <div className="space-y-2">
          <button
            onClick={() => { setAction('advance'); setError('') }}
            className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'advance' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
          >
            <p className="text-[13px] font-medium text-[#1F2937]">A. Avancar para Proxima Etapa</p>
            <p className="text-[11px] text-[#64748B] mt-1">
              {nextStep ? `Proxima etapa sequencial: ${nextStep.name}` : 'Nao existe etapa seguinte. O trabalho sera finalizado automaticamente.'}
            </p>
          </button>

          {action === 'advance' && nextStep && (
            <div className="pl-4">
              <Select
                label="Atribuir a"
                value={assignToId}
                onChange={setAssignToId}
                options={assigneeOptions}
                required
              />
            </div>
          )}

          <button
            onClick={() => { setAction('clinic_trial'); setError('') }}
            className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'clinic_trial' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
          >
            <p className="text-[13px] font-medium text-[#1F2937]">B. Enviar para Prova Clinica</p>
            <p className="text-[11px] text-[#64748B] mt-1">Atualiza estado para aguarda_aprovacao / Em prova.</p>
          </button>

          <button
            onClick={() => { setAction('finalize'); setError('') }}
            className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'finalize' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
          >
            <p className="text-[13px] font-medium text-[#1F2937]">C. Finalizar Trabalho</p>
            <p className="text-[11px] text-[#64748B] mt-1">Marca todas as etapas como concluidas e encerra o trabalho.</p>
          </button>

          <button
            onClick={() => { setAction('standby'); setError('') }}
            className={`w-full text-left border rounded-sm px-4 py-3 ${action === 'standby' ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
          >
            <p className="text-[13px] font-medium text-[#1F2937]">D. Colocar em Standby</p>
            <p className="text-[11px] text-[#64748B] mt-1">Justificacao obrigatoria e estado global em_standby.</p>
          </button>

          {action === 'standby' && (
            <textarea
              value={standbyReason}
              onChange={event => { setStandbyReason(event.target.value); setError('') }}
              rows={3}
              placeholder="Explique o motivo do standby..."
              className="w-full px-3 py-2.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none resize-none"
            />
          )}
        </div>

        {error && <p className="text-[11px] text-red-700">! {error}</p>}

        <div className="flex justify-end gap-2 pt-2">
          <Btn variant="ghost" onClick={onClose}>Cancelar</Btn>
          <Btn variant="primary" onClick={submit}>Confirmar decisao</Btn>
        </div>
      </div>
    </Modal>
  )
}

function AssumeStepModal({
  work,
  collaboratorId,
  collaboratorName,
  onClose,
  onDone,
}: {
  work: WorkOrder
  collaboratorId: string
  collaboratorName: string
  onClose: () => void
  onDone: () => void
}) {
  const [selectedStepId, setSelectedStepId] = useState('')
  const claimable = work.steps.filter((step, index) => {
    const statusAllowed = step.status === 'nao_iniciado' || step.status === 'standby'
    if (!statusAllowed) return false
    if (index === 0) return true
    return work.steps[index - 1].status === 'concluida'
  })

  return (
    <Modal title="Assumir Trabalho / Etapa" subtitle={work.ref} onClose={onClose}>
      <div className="p-6 space-y-4">
        <p className="text-[12px] text-[#475569]">Selecione a etapa pronta para execucao. O inicio sera registado automaticamente.</p>
        <div className="space-y-2 max-h-64 overflow-y-auto">
          {claimable.map(step => (
            <button
              key={step.id}
              onClick={() => setSelectedStepId(step.id)}
              className={`w-full text-left border rounded-sm px-4 py-3 ${selectedStepId === step.id ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF]'}`}
            >
              <p className="text-[13px] text-[#1F2937]">{step.name}</p>
              <p className="text-[10px] text-[#64748B] mt-1">{step.status === 'standby' ? 'Retoma de standby' : 'Por iniciar'}</p>
            </button>
          ))}
        </div>
        <div className="flex justify-end gap-2 pt-2">
          <Btn variant="ghost" onClick={onClose}>Cancelar</Btn>
          <Btn
            variant="primary"
            disabled={!selectedStepId}
            onClick={() => {
              assumeWorkStep({
                workId: work.id,
                stepId: selectedStepId,
                collaboratorId,
                collaboratorName,
              })
              onDone()
              onClose()
            }}
          >
            Assumir Etapa
          </Btn>
        </div>
      </div>
    </Modal>
  )
}

function WorkCard({ work, onSelect }: { work: WorkOrder; onSelect: () => void }) {
  return (
    <button
      onClick={onSelect}
      className="w-full text-left bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-4 hover:border-[#C9A227]/40 hover:shadow-sm active:bg-[#F9FAFB] transition-all"
    >
      <div className="flex items-start justify-between gap-3 mb-2">
        <div className="min-w-0">
          <p className="text-[10px] font-mono text-[#64748B]">{work.ref}</p>
          <p className="text-[13px] font-medium text-[#1F2937] leading-snug mt-0.5 truncate">{work.descricao}</p>
          <p className="text-[11px] text-[#475569]">{work.identificadorPaciente} · {work.clienteName}</p>
        </div>
        <DeadlineBadge prazo={work.prazo} />
      </div>
      <div className="flex items-center justify-between gap-3 mt-2 pt-2 border-t border-[#E5E7EB]">
        <div className="flex items-center gap-2 min-w-0">
          <NatureBadge natureza={work.natureza} />
          <span className="text-[11px] text-[#475569] truncate">{work.etapaAtual}</span>
        </div>
        <StatusBadge status={work.status} stage={work.etapaAtual} />
      </div>
    </button>
  )
}

export default function CollaboratorDashboard({
  user,
  activeView,
  onViewChange,
  onSelectWork,
}: CollaboratorDashboardProps) {
  const collaborator = COLABORADORES.find(item => item.email === user.email)
  const collaboratorId = collaborator?.id ?? user.id
  const collaboratorName = collaborator?.name ?? user.name
  const [orders, setOrders] = useState<WorkOrder[]>(getWorkOrders())
  const [assumeTargetId, setAssumeTargetId] = useState<string | null>(null)
  const [completeTargetId, setCompleteTargetId] = useState<string | null>(null)
  const [deadlineFilter, setDeadlineFilter] = useState<'all' | 'critical' | 'urgent'>('all')
  const { show, ToastEl } = useToast()

  useEffect(() => {
    const unsubscribe = subscribeLabData(() => {
      setOrders([...getWorkOrders()])
    })
    return unsubscribe
  }, [])

  const myWorks = useMemo(
    () => orders.filter(work => work.responsavelId === collaboratorId && work.status !== 'concluido'),
    [collaboratorId, orders],
  )

  const executing = myWorks.filter(work => work.steps.some(step => step.status === 'em_execucao' && step.collaboratorId === collaboratorId))
  const waiting = myWorks.filter(work => !executing.some(active => active.id === work.id))

  const available = useMemo(
    () => orders.filter(work => {
      if (work.status === 'concluido') return false
      const claimableStep = getClaimableStep(work)
      if (!claimableStep) return false
      const hasOwner = Boolean(work.responsavelId)
      const isMine = work.responsavelId === collaboratorId
      return !hasOwner || !isMine || claimableStep.collaboratorId !== collaboratorId
    }),
    [collaboratorId, orders],
  )

  const priorities = useMemo(() => {
    return [...myWorks]
      .sort((a, b) => {
        const daysA = Math.ceil((new Date(a.prazo).getTime() - Date.now()) / 86400000)
        const daysB = Math.ceil((new Date(b.prazo).getTime() - Date.now()) / 86400000)
        return daysA - daysB
      })
      .slice(0, 5)
  }, [myWorks])

  const deadlinesOrdered = useMemo(() => {
    const base = [...orders]
      .filter(work => work.status !== 'concluido')
      .sort((a, b) => new Date(a.prazo).getTime() - new Date(b.prazo).getTime())

    if (deadlineFilter === 'critical') {
      return base.filter(work => Math.ceil((new Date(work.prazo).getTime() - Date.now()) / 86400000) < 0)
    }
    if (deadlineFilter === 'urgent') {
      return base.filter(work => {
        const days = Math.ceil((new Date(work.prazo).getTime() - Date.now()) / 86400000)
        return days >= 0 && days <= 2
      })
    }
    return base
  }, [deadlineFilter, orders])

  const activeCount = myWorks.length
  const inExecutionCount = executing.length
  const urgentCount = deadlinesOrdered.filter(work => Math.ceil((new Date(work.prazo).getTime() - Date.now()) / 86400000) <= 2).length

  const assumeTarget = assumeTargetId ? orders.find(work => work.id === assumeTargetId) ?? null : null
  const completeTarget = completeTargetId ? orders.find(work => work.id === completeTargetId) ?? null : null

  return (
    <div className="flex-1 overflow-y-auto">
      {ToastEl}
      <div className="p-4 md:p-7 max-w-[1120px] space-y-6">
        {activeView === 'inicio' && (
          <>
            <div>
              <p className="text-[22px] font-serif text-[#1F2937] leading-tight">Ola, {user.name}</p>
              <p className="text-[12px] text-[#64748B] mt-1">{collaborator?.speciality ?? 'Tecnico de Laboratorio'}</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {[
                { id: 'meus' as CollaboratorView, label: 'Ativos', value: activeCount, color: 'text-slate-700', background: 'bg-slate-100 border-slate-200' },
                { id: 'meus' as CollaboratorView, label: 'Em Execucao', value: inExecutionCount, color: 'text-amber-800', background: 'bg-amber-50 border-amber-100' },
                { id: 'prazos' as CollaboratorView, label: 'Urgentes / Prazos Proximos', value: urgentCount, color: 'text-red-800', background: 'bg-red-50 border-red-100' },
              ].map(item => (
                <button
                  key={`${item.id}-${item.label}`}
                  onClick={() => onViewChange(item.id)}
                  className={`flex flex-col gap-1.5 p-4 rounded-xl border text-left hover:shadow-sm active:opacity-80 transition-all ${item.background}`}
                >
                  <p className={`text-[28px] font-serif leading-none ${item.color}`}>{item.value}</p>
                  <p className="text-[10px] text-[#475569] leading-tight">{item.label}</p>
                </button>
              ))}
            </div>

            <div>
              <p className="text-[14px] font-semibold text-[#1F2937] mb-2">Prioridade do Colaborador</p>
              <div className="space-y-2.5">
                {priorities.length === 0 ? (
                  <div className="py-8 text-center bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl">
                    <p className="text-[12px] text-[#64748B]">Sem ordens atribuídas neste momento.</p>
                  </div>
                ) : priorities.map(work => <WorkCard key={work.id} work={work} onSelect={() => onSelectWork(work.id)} />)}
              </div>
            </div>
          </>
        )}

        <div className="flex items-center justify-between gap-4">
          <p className="text-[14px] font-semibold text-[#1F2937]">{SECTION_TITLES[activeView]}</p>
          {activeView === 'prazos' && (
            <div className="flex items-center gap-1">
              {[
                { id: 'all', label: 'Todos' },
                { id: 'urgent', label: 'Urgentes' },
                { id: 'critical', label: 'Criticos' },
              ].map(filter => (
                <button
                  key={filter.id}
                  onClick={() => setDeadlineFilter(filter.id as 'all' | 'critical' | 'urgent')}
                  className={`px-2.5 py-1 text-[10px] font-mono border rounded-sm ${deadlineFilter === filter.id ? 'border-[#C9A227]/50 text-[#8A6F14] bg-[#C9A227]/10' : 'border-[#E5E7EB] text-[#64748B]'}`}
                >
                  {filter.label}
                </button>
              ))}
            </div>
          )}
        </div>

        {activeView === 'disponiveis' && (
          <div className="space-y-2.5">
            {available.length === 0 ? (
              <div className="py-10 text-center bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl">
                <p className="text-[12px] text-[#64748B]">Sem ordens disponiveis para assumir.</p>
              </div>
            ) : available.map(work => {
              const claimable = getClaimableStep(work)
              return (
                <div key={work.id} className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-4 flex items-center justify-between gap-4">
                  <div className="min-w-0">
                    <p className="text-[10px] font-mono text-[#64748B]">{work.ref}</p>
                    <p className="text-[13px] text-[#1F2937] font-medium truncate mt-0.5">{work.descricao}</p>
                    <p className="text-[11px] text-[#64748B] mt-1">Etapa pronta: {claimable?.name ?? work.etapaAtual}</p>
                  </div>
                  <div className="flex items-center gap-2 flex-shrink-0">
                    <DeadlineBadge prazo={work.prazo} />
                    <Btn size="sm" variant="primary" onClick={() => setAssumeTargetId(work.id)}>
                      Assumir Trabalho / Etapa
                    </Btn>
                  </div>
                </div>
              )
            })}
          </div>
        )}

        {activeView === 'meus' && (
          <div className="space-y-6">
            <div>
              <p className="text-[12px] font-semibold text-[#475569] mb-2">Em Espera / Por Iniciar</p>
              <div className="space-y-2.5">
                {waiting.length === 0 ? (
                  <div className="py-8 text-center bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl">
                    <p className="text-[12px] text-[#64748B]">Sem tarefas em espera.</p>
                  </div>
                ) : waiting.map(work => <WorkCard key={work.id} work={work} onSelect={() => onSelectWork(work.id)} />)}
              </div>
            </div>

            <div>
              <p className="text-[12px] font-semibold text-[#475569] mb-2">Em Processamento / Em Execucao</p>
              <div className="space-y-2.5">
                {executing.length === 0 ? (
                  <div className="py-8 text-center bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl">
                    <p className="text-[12px] text-[#64748B]">Sem tarefas em execucao.</p>
                  </div>
                ) : executing.map(work => {
                  const activeStep = work.steps.find(step => step.status === 'em_execucao' && step.collaboratorId === collaboratorId)
                  return (
                    <div key={work.id} className="bg-emerald-50/35 border border-emerald-400/50 rounded-xl px-5 py-4 shadow-[0_0_18px_rgba(16,185,129,0.08)]">
                      <div className="flex items-center justify-between gap-4">
                        <div className="min-w-0">
                          <p className="text-[10px] font-mono text-[#64748B]">{work.ref}</p>
                          <p className="text-[14px] font-medium text-[#1F2937] truncate">{work.descricao}</p>
                          <p className="text-[11px] text-emerald-900 mt-1">
                            Etapa atual: {activeStep?.name ?? work.etapaAtual} · {formatElapsed(activeStep?.startedAt)}
                          </p>
                          <p className="text-[11px] text-[#475569] mt-1">
                            {work.identificadorPaciente} · Dentes FDI: {work.dentes.join(', ')} · Material: {work.material}
                          </p>
                        </div>
                        <div className="flex items-center gap-2 flex-shrink-0">
                          <Btn size="sm" variant="secondary" onClick={() => onSelectWork(work.id)}>Ver Detalhes</Btn>
                          <Btn
                            size="sm"
                            variant="secondary"
                            onClick={() => {
                              completeWorkStepDecision({
                                workId: work.id,
                                collaboratorId,
                                collaboratorName,
                                action: 'standby',
                                standbyReason: 'Standby acionado no painel de execucao.',
                              })
                              show('Trabalho colocado em standby')
                            }}
                          >
                            Colocar em Standby
                          </Btn>
                          <Btn size="sm" variant="primary" onClick={() => setCompleteTargetId(work.id)}>Concluir Etapa</Btn>
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        )}

        {activeView === 'prazos' && (
          <div className="space-y-2.5">
            {deadlinesOrdered.length === 0 ? (
              <div className="py-8 text-center bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl">
                <p className="text-[12px] text-[#64748B]">Sem trabalhos para o filtro atual.</p>
              </div>
            ) : deadlinesOrdered.map(work => {
              const days = Math.ceil((new Date(work.prazo).getTime() - Date.now()) / 86400000)
              return (
                <button
                  key={work.id}
                  onClick={() => onSelectWork(work.id)}
                  className="w-full text-left bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-4 hover:border-[#C9A227]/30 transition-colors"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="text-[10px] font-mono text-[#64748B]">{work.ref}</p>
                      <p className="text-[13px] text-[#1F2937] font-medium truncate">{work.descricao}</p>
                      <p className="text-[11px] text-[#64748B] mt-1">{work.etapaAtual} · {work.identificadorPaciente}</p>
                    </div>
                    <div className="flex items-center gap-2 flex-shrink-0">
                      <DaysBadge prazo={work.prazo} />
                      <span className={`text-[10px] font-mono px-2 py-1 rounded-md ${days < 0 ? 'bg-red-50 text-red-800' : days <= 2 ? 'bg-amber-50 text-amber-800' : 'bg-slate-100 text-slate-700'}`}>
                        {new Date(work.prazo).toLocaleDateString('pt-PT')}
                      </span>
                    </div>
                  </div>
                </button>
              )
            })}
          </div>
        )}
      </div>

      {assumeTarget && (
        <AssumeStepModal
          work={assumeTarget}
          collaboratorId={collaboratorId}
          collaboratorName={collaboratorName}
          onClose={() => setAssumeTargetId(null)}
          onDone={() => show('Etapa assumida e inicio registado')}
        />
      )}

      {completeTarget && (
        <CompleteStepModal
          work={completeTarget}
          collaboratorId={collaboratorId}
          collaboratorName={collaboratorName}
          onClose={() => setCompleteTargetId(null)}
          onDone={message => show(message)}
        />
      )}
    </div>
  )
}
