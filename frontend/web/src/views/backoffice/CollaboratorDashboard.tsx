import { useState } from 'react'
import type { User, WorkNature, WorkOrder } from '../../data'
import { COLABORADORES, WORK_ORDERS, WORK_TYPES } from '../../data'
import {
  Btn,
  DeadlineBadge,
  NatureBadge,
  Select,
  StatusBadge,
  useToast,
} from '../../components/ui'
import StepCompletion from '../../components/StepCompletion'
import {
  canManageMockStep,
  claimMockStep,
  isMockWorkClaimable,
  useMockWorkState,
} from '../../mockWorkStore'
import type { StepTransition } from '../../workflow'
import {
  DEADLINE_OPTIONS,
  matchesDeadline,
  type DeadlineFilter,
} from '../../workFilters'

export type CollaboratorView = 'inicio' | 'disponiveis' | 'meus' | 'prazos'

const SECTION_TITLES: Record<CollaboratorView, string> = {
  inicio: 'Prioridades e Urgências',
  disponiveis: 'Trabalhos Disponíveis',
  meus: 'Trabalhos Atribuídos',
  prazos: 'Gestão de Prazos',
}

interface CollaboratorDashboardProps {
  user: User
  activeView: CollaboratorView
  onViewChange: (view: CollaboratorView) => void
  onSelectWork: (id: string) => void
}

function WorkCard({
  work,
  onSelect,
}: {
  work: WorkOrder
  onSelect: () => void
}) {
  return (
    <button
      onClick={onSelect}
      className="w-full text-left bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-4 hover:border-[#C9A227]/40 hover:shadow-sm active:bg-[#F9FAFB] transition-all"
    >
      <div className="flex items-start justify-between gap-3 mb-2">
        <div className="min-w-0">
          <p className="text-[10px] font-mono text-[#64748B]">{work.ref}</p>
          <p className="text-[13px] font-medium text-[#1F2937] leading-snug mt-0.5 truncate">
            {work.descricao}
          </p>
          <p className="text-[11px] text-[#475569]">{work.clienteName}</p>
        </div>
        <DeadlineBadge prazo={work.prazo} status={work.status} />
      </div>
      <div className="flex items-center justify-between gap-3 mt-2 pt-2 border-t border-[#E5E7EB]">
        <div className="flex items-center gap-2 min-w-0">
          <NatureBadge natureza={work.natureza} />
          <span className="text-[11px] text-[#475569] truncate">
            {work.etapaAtual}
          </span>
        </div>
        <StatusBadge status={work.status} stage={work.etapaAtual} />
      </div>
    </button>
  )
}

function QueuedWorkCard({
  work,
  onSelect,
}: {
  work: WorkOrder
  onSelect: () => void
}) {
  return (
    <div className="w-full bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl px-5 py-4 hover:border-[#C9A227]/30 hover:shadow-sm transition-all">
      <div className="flex items-center gap-5">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1.5">
            <span className="text-[10px] font-mono text-[#64748B]">
              {work.ref}
            </span>
            <span className="inline-flex items-center gap-1.5 px-2 py-1 rounded-md bg-slate-100 text-[9px] font-mono text-slate-700 uppercase tracking-wider">
              <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
              Em espera
            </span>
          </div>
          <p className="text-[14px] font-medium text-[#1F2937] truncate">
            {work.descricao}
          </p>
          <div className="flex items-center gap-2 mt-2">
            <NatureBadge natureza={work.natureza} />
            <span className="text-[11px] text-[#475569]">
              {work.clienteName}
            </span>
            <span className="text-[#D1D5DB]">·</span>
            <span className="text-[11px] text-[#64748B]">
              {work.etapaAtual}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-4 flex-shrink-0">
          <DeadlineBadge prazo={work.prazo} status={work.status} />
          <button
            onClick={onSelect}
            className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-[#C9A227] text-[#1F2937] rounded-lg text-[12px] font-semibold hover:bg-[#D4AF37] transition-colors shadow-sm"
          >
            <span className="text-[10px]">▶</span>
            Iniciar Etapa
          </button>
        </div>
      </div>
    </div>
  )
}

function ActiveManagedWorkCard({
  work,
  onStandby,
  onComplete,
  completing,
}: {
  work: WorkOrder
  onStandby: () => void
  onComplete: () => void
  completing: boolean
}) {
  return (
    <div className="w-full bg-emerald-50/35 border border-emerald-400/50 rounded-xl px-5 py-4 shadow-[0_0_18px_rgba(16,185,129,0.08)]">
      <div className="flex items-center gap-5">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1.5">
            <span className="text-[10px] font-mono text-[#64748B]">
              {work.ref}
            </span>
            <span className="inline-flex items-center gap-1.5 px-2 py-1 rounded-md bg-emerald-50 text-[9px] font-mono font-semibold text-emerald-800 uppercase tracking-wider">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Em processamento
            </span>
          </div>
          <p className="text-[14px] font-medium text-[#1F2937] truncate">
            {work.descricao}
          </p>
          <div className="flex items-center gap-2 mt-2">
            <NatureBadge natureza={work.natureza} />
            <span className="text-[11px] text-[#475569]">
              {work.clienteName}
            </span>
            <span className="text-[#D1D5DB]">·</span>
            <span className="text-[11px] text-emerald-800">
              {work.etapaAtual}
            </span>
          </div>
        </div>

        <div className="flex items-center gap-2 flex-shrink-0">
          <DeadlineBadge prazo={work.prazo} status={work.status} />
          <button
            onClick={onStandby}
            disabled={completing}
            className="px-3.5 py-2.5 bg-[#FFFFFF] border border-[#D1D5DB] text-[#475569] rounded-lg text-[11px] font-semibold hover:border-amber-400 hover:text-amber-800 disabled:opacity-60 transition-colors"
          >
            Standby
          </button>
          <button
            onClick={onComplete}
            disabled={completing}
            className="inline-flex items-center gap-2 px-4 py-2.5 bg-emerald-600 text-white rounded-lg text-[11px] font-semibold hover:bg-emerald-700 disabled:opacity-70 transition-colors"
          >
            <span>✓</span>
            {completing ? 'Etapa concluída' : 'Concluir Etapa'}
          </button>
        </div>
      </div>
    </div>
  )
}

export default function CollaboratorDashboard({
  user,
  activeView,
  onViewChange,
  onSelectWork,
}: CollaboratorDashboardProps) {
  useMockWorkState()
  const collaborator = COLABORADORES.find((item) => item.email === user.email)
  const collaboratorId = collaborator?.id ?? user.id
  const [completionWorkId, setCompletionWorkId] = useState<string | null>(null)
  const [completionAction, setCompletionAction] =
    useState<StepTransition['action']>('advance')
  const [availableType, setAvailableType] = useState('')
  const [availableNature, setAvailableNature] = useState<WorkNature | ''>('')
  const [availableDeadline, setAvailableDeadline] = useState<DeadlineFilter>('')
  const completionWork = WORK_ORDERS.find(
    (work) => work.id === completionWorkId,
  )
  const isCompleting = completionWorkId !== null
  const { show, ToastEl } = useToast()
  const myWorks = WORK_ORDERS.filter(
    (work) =>
      work.responsavelId === collaboratorId && work.status !== 'concluido',
  )
  const inProgress = myWorks.filter((work) => canManageMockStep(work, user))
  const available = WORK_ORDERS.filter(isMockWorkClaimable)
  const filteredAvailable = available.filter(
    (work) =>
      (!availableType || work.tipoId === availableType) &&
      (!availableNature || work.natureza === availableNature) &&
      matchesDeadline(work, availableDeadline),
  )
  const urgent = WORK_ORDERS.filter((work) => {
    const days = Math.ceil(
      (new Date(work.prazo).getTime() - Date.now()) / 86400000,
    )
    return days <= 3 && work.status !== 'concluido'
  }).sort((a, b) => new Date(a.prazo).getTime() - new Date(b.prazo).getTime())
  const priorities = [...myWorks]
    .sort((a, b) => {
      const executionPriority =
        Number(b.status === 'em_producao') - Number(a.status === 'em_producao')
      return (
        executionPriority ||
        new Date(a.prazo).getTime() - new Date(b.prazo).getTime()
      )
    })
    .slice(0, 3)

  const lists: Record<CollaboratorView, WorkOrder[]> = {
    inicio: priorities,
    disponiveis: filteredAvailable,
    meus: myWorks,
    prazos: urgent,
  }
  const visibleWorks = lists[activeView]

  const startWork = (workId: string) => {
    try {
      claimMockStep(workId, user)
      onViewChange('meus')
    } catch (error) {
      show(
        error instanceof Error
          ? error.message
          : 'Não foi possível assumir a etapa.',
        'error',
      )
    }
  }

  const completeWork = (
    workId: string,
    action: StepTransition['action'] = 'advance',
  ) => {
    setCompletionAction(action)
    setCompletionWorkId(workId)
  }

  return (
    <div className="flex-1 overflow-y-auto">
      {ToastEl}
      {completionWork && (
        <StepCompletion
          key={completionWork.id}
          work={completionWork}
          user={user}
          initialAction={completionAction}
          onClose={() => setCompletionWorkId(null)}
          onDone={() => {
            setCompletionWorkId(null)
            show('Etapa atualizada com sucesso')
          }}
        />
      )}
      <div className="p-4 md:p-[35px] max-w-[1500px] space-y-6">
        {activeView === 'inicio' && (
          <>
            <div>
              <p className="text-[22px] font-serif text-[#1F2937] leading-tight">
                Olá, {user.name}
              </p>
              <p className="text-[12px] text-[#64748B] mt-1">Colaborador</p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {[
                {
                  id: 'meus' as CollaboratorView,
                  label: 'Ativos',
                  value: myWorks.length,
                  color: 'text-slate-700',
                  background: 'bg-slate-100 border-slate-200',
                },
                {
                  id: 'meus' as CollaboratorView,
                  label: 'Em execução',
                  value: inProgress.length,
                  color: 'text-amber-800',
                  background: 'bg-amber-50 border-amber-100',
                },
                {
                  id: 'prazos' as CollaboratorView,
                  label: 'Urgentes',
                  value: urgent.length,
                  color: 'text-red-800',
                  background: 'bg-red-50 border-red-100',
                },
              ].map((item) => (
                <button
                  key={item.label}
                  onClick={() => onViewChange(item.id)}
                  className={`flex flex-col gap-1.5 p-4 rounded-xl border text-left hover:shadow-sm active:opacity-80 transition-all ${item.background}`}
                >
                  <p
                    className={`text-[28px] font-serif leading-none ${item.color}`}
                  >
                    {item.value}
                  </p>
                  <p className="text-[10px] text-[#475569] leading-tight">
                    {item.label}
                  </p>
                </button>
              ))}
            </div>
          </>
        )}

        <div className="flex items-center justify-between gap-4">
          <p className="text-[14px] font-semibold text-[#1F2937]">
            {SECTION_TITLES[activeView]}
          </p>
          {activeView === 'inicio' && (
            <button
              onClick={() => onViewChange('prazos')}
              className="text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors"
            >
              Ver todos →
            </button>
          )}
        </div>

        {activeView === 'disponiveis' && (
          <div className="flex flex-wrap items-end gap-3 rounded-xl border border-[var(--line)] bg-[var(--surface)] p-4">
            <div className="min-w-52 flex-1">
              <Select
                label="Tipo de trabalho"
                value={availableType}
                onChange={setAvailableType}
                options={WORK_TYPES.map((type) => ({
                  value: type.id,
                  label: type.name,
                }))}
              />
            </div>
            <div className="min-w-44 flex-1">
              <Select
                label="Natureza"
                value={availableNature}
                onChange={(value) =>
                  setAvailableNature(value as WorkNature | '')
                }
                options={[
                  { value: 'fisico', label: 'Físico' },
                  { value: 'digital', label: 'Digital' },
                ]}
              />
            </div>
            <div className="min-w-44 flex-1">
              <Select
                label="Urgência / Prazo"
                value={availableDeadline}
                onChange={(value) =>
                  setAvailableDeadline(value as DeadlineFilter)
                }
                options={DEADLINE_OPTIONS.filter((option) => option.value)}
              />
            </div>
            {(availableType || availableNature || availableDeadline) && (
              <Btn
                variant="ghost"
                onClick={() => {
                  setAvailableType('')
                  setAvailableNature('')
                  setAvailableDeadline('')
                }}
              >
                Limpar filtros
              </Btn>
            )}
            <span className="pb-2 text-[11px] font-mono text-[var(--muted)]">
              {filteredAvailable.length} trabalho
              {filteredAvailable.length !== 1 ? 's' : ''}
            </span>
          </div>
        )}

        <div
          className={
            activeView === 'inicio'
              ? 'grid grid-cols-1 gap-5 xl:grid-cols-2'
              : 'space-y-2.5'
          }
        >
          {activeView === 'inicio' ? (
            <>
              <section className="rounded-xl border border-[#E5E7EB] bg-[#FFFFFF] p-4">
                <div className="mb-4 flex items-center justify-between">
                  <div>
                    <p className="text-[13px] font-semibold text-[#1F2937]">
                      Disponíveis
                    </p>
                    <p className="mt-0.5 text-[10px] text-[#64748B]">
                      Fila partilhada pronta a assumir
                    </p>
                  </div>
                  <span className="rounded-full bg-[var(--processing-soft)] px-2.5 py-1 text-[10px] font-semibold text-[var(--processing)]">
                    {available.length}
                  </span>
                </div>
                <div className="space-y-2.5">
                  {available.slice(0, 4).map((work) => (
                    <WorkCard
                      key={work.id}
                      work={work}
                      onSelect={() => onSelectWork(work.id)}
                    />
                  ))}
                </div>
              </section>
              <section className="rounded-xl border border-[#E5E7EB] bg-[#FFFFFF] p-4">
                <div className="mb-4 flex items-center justify-between">
                  <div>
                    <p className="text-[13px] font-semibold text-[#1F2937]">
                      Os Meus Trabalhos
                    </p>
                    <p className="mt-0.5 text-[10px] text-[#64748B]">
                      Etapas atribuídas e em curso
                    </p>
                  </div>
                  <span className="rounded-full bg-[var(--success-soft)] px-2.5 py-1 text-[10px] font-semibold text-[var(--success)]">
                    {myWorks.length}
                  </span>
                </div>
                <div className="space-y-2.5">
                  {myWorks
                    .slice(0, 4)
                    .map((work) =>
                      inProgress.includes(work) ? (
                        <ActiveManagedWorkCard
                          key={work.id}
                          work={work}
                          onStandby={() => completeWork(work.id, 'standby')}
                          onComplete={() => completeWork(work.id)}
                          completing={isCompleting}
                        />
                      ) : (
                        <WorkCard
                          key={work.id}
                          work={work}
                          onSelect={() => onSelectWork(work.id)}
                        />
                      ),
                    )}
                </div>
              </section>
            </>
          ) : visibleWorks.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl">
              <span className="text-3xl text-[#E5E7EB] mb-3">◫</span>
              <p className="text-[13px] text-[#6B7280] font-serif">
                Sem trabalhos
              </p>
            </div>
          ) : activeView === 'meus' ? (
            visibleWorks.map((work) =>
              inProgress.includes(work) ? (
                <ActiveManagedWorkCard
                  key={work.id}
                  work={work}
                  onStandby={() => completeWork(work.id, 'standby')}
                  onComplete={() => completeWork(work.id)}
                  completing={isCompleting}
                />
              ) : isMockWorkClaimable(work) ? (
                <QueuedWorkCard
                  key={work.id}
                  work={work}
                  onSelect={() => startWork(work.id)}
                />
              ) : (
                <WorkCard
                  key={work.id}
                  work={work}
                  onSelect={() => onSelectWork(work.id)}
                />
              ),
            )
          ) : (
            visibleWorks.map((work) => (
              <WorkCard
                key={work.id}
                work={work}
                onSelect={() => onSelectWork(work.id)}
              />
            ))
          )}
        </div>
      </div>
    </div>
  )
}
