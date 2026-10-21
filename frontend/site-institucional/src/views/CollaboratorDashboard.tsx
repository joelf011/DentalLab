import { useState } from 'react'
import type { User, WorkOrder } from '../data'
import { COLABORADORES, WORK_ORDERS } from '../data'
import { DeadlineBadge, NatureBadge, StatusBadge, useToast } from '../components/ui'

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
          <p className="text-[11px] text-[#475569]">{work.clienteName}</p>
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

function QueuedWorkCard({ work, onSelect }: { work: WorkOrder; onSelect: () => void }) {
  return (
    <div className="w-full bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl px-5 py-4 hover:border-[#C9A227]/30 hover:shadow-sm transition-all">
      <div className="flex items-center gap-5">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1.5">
            <span className="text-[10px] font-mono text-[#64748B]">{work.ref}</span>
            <span className="inline-flex items-center gap-1.5 px-2 py-1 rounded-md bg-slate-100 text-[9px] font-mono text-slate-700 uppercase tracking-wider">
              <span className="w-1.5 h-1.5 rounded-full bg-slate-400" />
              Em espera
            </span>
          </div>
          <p className="text-[14px] font-medium text-[#1F2937] truncate">{work.descricao}</p>
          <div className="flex items-center gap-2 mt-2">
            <NatureBadge natureza={work.natureza} />
            <span className="text-[11px] text-[#475569]">{work.clienteName}</span>
            <span className="text-[#D1D5DB]">·</span>
            <span className="text-[11px] text-[#64748B]">{work.etapaAtual}</span>
          </div>
        </div>

        <div className="flex items-center gap-4 flex-shrink-0">
          <DeadlineBadge prazo={work.prazo} />
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
            <span className="text-[10px] font-mono text-[#64748B]">{work.ref}</span>
            <span className="inline-flex items-center gap-1.5 px-2 py-1 rounded-md bg-emerald-50 text-[9px] font-mono font-semibold text-emerald-800 uppercase tracking-wider">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              Em processamento
            </span>
          </div>
          <p className="text-[14px] font-medium text-[#1F2937] truncate">{work.descricao}</p>
          <div className="flex items-center gap-2 mt-2">
            <NatureBadge natureza={work.natureza} />
            <span className="text-[11px] text-[#475569]">{work.clienteName}</span>
            <span className="text-[#D1D5DB]">·</span>
            <span className="text-[11px] text-emerald-800">{work.etapaAtual}</span>
          </div>
        </div>

        <div className="flex items-center gap-2 flex-shrink-0">
          <DeadlineBadge prazo={work.prazo} />
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
  const collaborator = COLABORADORES.find(item => item.email === user.email)
  const initialActiveWork = WORK_ORDERS.find(
    work => work.responsavelId === collaborator?.id && work.status === 'em_producao',
  )
  const [activeWorkId, setActiveWorkId] = useState<string | null>(initialActiveWork?.id ?? null)
  const [completedWorkIds, setCompletedWorkIds] = useState<string[]>([])
  const [isCompleting, setIsCompleting] = useState(false)
  const { show, ToastEl } = useToast()
  const myWorks = WORK_ORDERS.filter(
    work => work.responsavelId === collaborator?.id
      && work.status !== 'concluido'
      && !completedWorkIds.includes(work.id),
  )
  const activeWork = myWorks.find(work => work.id === activeWorkId) ?? null
  const inProgress = activeWork ? [activeWork] : []
  const available = WORK_ORDERS.filter(
    work => work.status === 'por_receber' || (!work.responsavelId && work.status !== 'concluido'),
  )
  const urgent = WORK_ORDERS.filter(work => {
    const days = Math.ceil((new Date(work.prazo).getTime() - Date.now()) / 86400000)
    return days <= 3 && work.status !== 'concluido'
  }).sort((a, b) => new Date(a.prazo).getTime() - new Date(b.prazo).getTime())
  const priorities = [...myWorks]
    .sort((a, b) => {
      const executionPriority = Number(b.status === 'em_producao') - Number(a.status === 'em_producao')
      return executionPriority || new Date(a.prazo).getTime() - new Date(b.prazo).getTime()
    })
    .slice(0, 3)

  const lists: Record<CollaboratorView, WorkOrder[]> = {
    inicio: priorities,
    disponiveis: available,
    meus: myWorks,
    prazos: urgent,
  }
  const visibleWorks = lists[activeView]

  const startWork = (workId: string) => {
    setActiveWorkId(workId)
    onViewChange('meus')
  }

  const placeOnStandby = () => {
    setActiveWorkId(null)
    show('Trabalho colocado em standby')
  }

  const completeWork = () => {
    if (!activeWorkId || isCompleting) return
    const completedId = activeWorkId
    setIsCompleting(true)
    show('Etapa concluída')
    setTimeout(() => {
      setCompletedWorkIds(previous => [...previous, completedId])
      setActiveWorkId(null)
      setIsCompleting(false)
    }, 700)
  }

  return (
    <div className="flex-1 overflow-y-auto">
      {ToastEl}
      <div className="p-4 md:p-7 max-w-[1100px] space-y-6">
        {activeView === 'inicio' && (
          <>
            <div>
              <p className="text-[22px] font-serif text-[#1F2937] leading-tight">Olá, {user.name}</p>
              <p className="text-[12px] text-[#64748B] mt-1">{collaborator?.speciality ?? 'Colaborador'}</p>
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
          </>
        )}

        <div className="flex items-center justify-between gap-4">
          <p className="text-[14px] font-semibold text-[#1F2937]">{SECTION_TITLES[activeView]}</p>
          {activeView === 'inicio' && (
            <button
              onClick={() => onViewChange('prazos')}
              className="text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors"
            >
              Ver todos →
            </button>
          )}
        </div>

        <div className="space-y-2.5">
          {visibleWorks.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-16 text-center bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl">
              <span className="text-3xl text-[#E5E7EB] mb-3">◫</span>
              <p className="text-[13px] text-[#6B7280] font-serif">Sem trabalhos</p>
            </div>
          ) : activeView === 'meus' ? (
            visibleWorks.map(work => work.id === activeWorkId ? (
              <ActiveManagedWorkCard
                key={work.id}
                work={work}
                onStandby={placeOnStandby}
                onComplete={completeWork}
                completing={isCompleting}
              />
            ) : (
              <QueuedWorkCard key={work.id} work={work} onSelect={() => startWork(work.id)} />
            ))
          ) : (
            visibleWorks.map(work => (
              <WorkCard key={work.id} work={work} onSelect={() => onSelectWork(work.id)} />
            ))
          )}
        </div>
      </div>
    </div>
  )
}
