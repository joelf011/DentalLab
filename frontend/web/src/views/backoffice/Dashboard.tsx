import { WORK_ORDERS, COLABORADORES, type WorkOrder } from '../../data'
import {
  StatusBadge,
  DeadlineBadge,
  Avatar,
  WarningBanner,
} from '../../components/ui'
import { useMockWorkState } from '../../mockWorkStore'

interface DashboardProps {
  onSelectWork: (id: string) => void
  onNav: (section: string) => void
}

const EVENTS = [
  {
    text: 'Novo trabalho recebido — Clínica Sorrisão',
    time: '14:22',
    icon: '+',
    color: 'text-emerald-700',
  },
  {
    text: `Ana Martins assumiu etapa "Articulação" — LCD-${new Date().getFullYear()}-0847`,
    time: '13:55',
    icon: '◑',
    color: 'text-amber-700',
  },
  {
    text: `LCD-${new Date().getFullYear()}-0849 aguarda aprovação do cliente`,
    time: '12:10',
    icon: '◷',
    color: 'text-sky-700',
  },
  {
    text: `LCD-${new Date().getFullYear()}-0844 marcado como concluído`,
    time: '11:30',
    icon: '✓',
    color: 'text-emerald-700',
  },
  {
    text: `Jorge Vieira colocou LCD-${new Date().getFullYear()}-0848 em standby`,
    time: '09:15',
    icon: '⊠',
    color: 'text-orange-700',
  },
]

function KpiCard({
  label,
  value,
  sub,
  tone = 'neutral',
}: {
  label: string
  value: number
  sub: string
  tone?: 'neutral' | 'amber' | 'orange' | 'red' | 'green'
}) {
  const styles = {
    neutral: 'bg-white border-[#E5E7EB]',
    amber: 'bg-amber-50 border-amber-100',
    orange: 'bg-orange-50 border-orange-100',
    red: 'bg-red-50 border-red-100',
    green: 'bg-emerald-50 border-emerald-100',
  }[tone]
  const valueColor =
    tone === 'red'
      ? 'text-red-800'
      : tone === 'orange'
        ? 'text-orange-800'
        : tone === 'amber'
          ? 'text-amber-800'
          : tone === 'green'
            ? 'text-emerald-800'
            : 'text-[#1F2937]'

  return (
    <div className={`rounded-xl border p-5 space-y-2 shadow-sm ${styles}`}>
      <p className="text-[10px] font-mono text-[#6B7280] uppercase tracking-widest">
        {label}
      </p>
      <p
        className={`text-[36px] leading-none font-serif font-semibold ${valueColor}`}
      >
        {value}
      </p>
      <p className="text-[11px] text-[#64748B] font-mono">{sub}</p>
    </div>
  )
}

function PriorityDeadline({ prazo }: { prazo: string }) {
  const isPast = new Date(prazo).getTime() < Date.now()
  return (
    <span
      className={`w-14 text-center text-[11px] font-mono ${
        isPast ? 'text-red-700' : 'text-[#475569]'
      }`}
    >
      {new Date(prazo).toLocaleDateString('pt-PT', {
        day: '2-digit',
        month: '2-digit',
      })}
    </span>
  )
}

function PriorityRow({
  order,
  onSelect,
}: {
  order: WorkOrder
  onSelect: () => void
}) {
  const days = Math.ceil(
    (new Date(order.prazo).getTime() - Date.now()) / 86400000,
  )
  const isLate = days < 0
  const isUrgent = !isLate && days <= 2
  const rowBg = isLate
    ? 'bg-red-500/4 hover:bg-red-500/8'
    : isUrgent
      ? 'bg-orange-400/4 hover:bg-orange-400/8'
      : 'hover:bg-slate-50'
  return (
    <div
      onClick={onSelect}
      className={`grid grid-cols-[110px_minmax(180px,1fr)_96px_112px_64px_132px] items-center gap-3 px-5 py-3 min-w-[760px] cursor-pointer transition-colors border-b border-[#E5E7EB] last:border-b-0 ${rowBg}`}
    >
      <span className="text-[11px] font-mono text-[#64748B]">{order.ref}</span>
      <div className="flex-1 min-w-0">
        <p className="text-[12px] text-[#1F2937] truncate">{order.descricao}</p>
        <p className="text-[11px] text-[#64748B] truncate">
          {order.clienteName} · {order.identificadorPaciente}
        </p>
      </div>
      <span className="text-[11px] text-[#475569] truncate">
        {order.etapaAtual}
      </span>
      <div className="flex items-center gap-1.5 min-w-0">
        {order.responsavelName && order.responsavelName !== '—' ? (
          <>
            <Avatar name={order.responsavelName} size="xs" />
            <span className="text-[11px] text-[#64748B] truncate">
              {order.responsavelName.split(' ')[0]}
            </span>
          </>
        ) : (
          <span className="text-[11px] text-[#6B7280]">—</span>
        )}
      </div>
      <div className="flex justify-center">
        <PriorityDeadline prazo={order.prazo} />
      </div>
      <div className="flex justify-start">
        <StatusBadge status={order.status} stage={order.etapaAtual} />
      </div>
    </div>
  )
}

function StaffLoad({ onOpenTeam }: { onOpenTeam: () => void }) {
  return (
    <section className="overflow-hidden rounded-xl border border-[var(--line)] bg-[var(--surface)] shadow-sm">
      <div className="flex items-center justify-between border-b border-[var(--line)] px-5 py-4">
        <div>
          <h2 className="text-[13px] font-semibold text-[var(--ink)]">
            Carga por Colaborador
          </h2>
          <p className="mt-0.5 text-[10px] text-[var(--muted)]">
            Capacidade e distribuição atual da equipa
          </p>
        </div>
        <button
          onClick={onOpenTeam}
          className="text-[11px] text-[var(--muted)] hover:text-[var(--gold-ink)] transition-colors"
        >
          Ver equipa →
        </button>
      </div>
      <div className="grid grid-cols-2 divide-x divide-[var(--soft)] lg:grid-cols-3 xl:grid-cols-5">
        {COLABORADORES.filter((c) => c.role !== 'admin' && !c.deletedAt).map(
          (c) => (
            <div key={c.id} className="flex flex-col gap-2 p-4">
              <div className="flex items-center gap-2">
                <Avatar name={c.name} size="xs" />
                <div className="min-w-0">
                  <p className="truncate text-[11px] text-[var(--ink)]">
                    {c.name}
                  </p>
                  <div className="flex items-center gap-1">
                    <span
                      className={`h-1.5 w-1.5 flex-shrink-0 rounded-full ${
                        c.status === 'disponivel'
                          ? 'bg-emerald-500'
                          : c.status === 'ocupado'
                            ? 'bg-amber-500'
                            : 'bg-zinc-500'
                      }`}
                    />
                    <span className="truncate text-[9px] text-[var(--muted)]">
                      Colaborador
                    </span>
                  </div>
                </div>
              </div>
              <div className="mt-1 flex items-center justify-between">
                <span className="text-[10px] text-[var(--muted)]">Ativos</span>
                <span
                  className={`text-[18px] font-serif ${
                    c.activeWorks > 2 ? 'text-amber-700' : 'text-[var(--ink)]'
                  }`}
                >
                  {c.activeWorks}
                </span>
              </div>
              <div className="h-1 overflow-hidden rounded-full bg-[var(--line)]">
                <div
                  className={`h-full rounded-full ${
                    c.activeWorks >= 3 ? 'bg-amber-500' : 'bg-[var(--gold)]'
                  }`}
                  style={{ width: `${Math.min(100, c.activeWorks * 33)}%` }}
                />
              </div>
            </div>
          ),
        )}
      </div>
    </section>
  )
}

export default function Dashboard({ onSelectWork, onNav }: DashboardProps) {
  useMockWorkState()
  const active = WORK_ORDERS.filter((w) => w.status !== 'concluido')
  const porReceber = WORK_ORDERS.filter(
    (w) => w.status === 'por_receber',
  ).length
  const emProducao = WORK_ORDERS.filter(
    (w) => w.status === 'em_producao',
  ).length
  const emStandby = WORK_ORDERS.filter((w) => w.status === 'em_standby').length
  const concluidos = WORK_ORDERS.filter((w) => w.status === 'concluido').length

  const urgentes = active
    .filter((w) => w.status !== 'concluido')
    .sort((a, b) => new Date(a.prazo).getTime() - new Date(b.prazo).getTime())

  const proximosPrazo = urgentes.filter((w) => {
    const d = Math.ceil((new Date(w.prazo).getTime() - Date.now()) / 86400000)
    return d <= 5
  }).length

  const standbyOrders = WORK_ORDERS.filter((w) => w.status === 'em_standby')
  const lateOrders = WORK_ORDERS.filter((w) => {
    const d = Math.ceil((new Date(w.prazo).getTime() - Date.now()) / 86400000)
    return d < 0 && w.status !== 'concluido'
  })

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="p-4 md:p-7 space-y-6 max-w-[1600px]">
        {/* KPIs */}
        <div className="grid grid-cols-2 lg:grid-cols-5 gap-3">
          <KpiCard
            label="Por Receber"
            value={porReceber}
            sub="aguardam aceitação"
          />
          <KpiCard
            label="Em Produção"
            value={emProducao}
            sub="trabalhos activos"
            tone="amber"
          />
          <KpiCard
            label="Em Standby"
            value={emStandby}
            sub="aguardam retoma"
            tone="orange"
          />
          <KpiCard
            label="Próx. do Prazo"
            value={proximosPrazo}
            sub="nos próximos 5 dias"
            tone={proximosPrazo > 2 ? 'red' : 'neutral'}
          />
          <KpiCard
            label="Concluídos (mês)"
            value={concluidos}
            sub={new Date().toLocaleDateString('pt-PT', {
              month: 'long',
              year: 'numeric',
              timeZone: 'Europe/Lisbon',
            })}
            tone="green"
          />
        </div>

        {lateOrders.length > 0 && (
          <WarningBanner
            message={`${lateOrders.length} trabalho${
              lateOrders.length > 1 ? 's' : ''
            } com prazo excedido — requer atenção imediata.`}
          />
        )}

        <StaffLoad onOpenTeam={() => onNav('colaboradores')} />

        {/* Main grid */}
        <div className="grid grid-cols-1 xl:grid-cols-3 gap-5">
          {/* Priority work orders */}
          <div className="xl:col-span-2 bg-white rounded-md shadow-sm overflow-hidden flex flex-col">
            <div className="flex items-center justify-between px-5 py-4 border-b border-[#E5E7EB]">
              <div className="flex items-center gap-2">
                <h2 className="text-[13px] font-semibold text-[#1F2937]">
                  Trabalhos Prioritários
                </h2>
                <span className="text-[10px] font-mono font-medium px-2 py-1 bg-orange-50 text-orange-800 rounded-md">
                  {urgentes.length} activos
                </span>
              </div>
              <button
                onClick={() => onNav('trabalhos')}
                className="text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors"
              >
                Ver todos →
              </button>
            </div>

            {/* Sub-header */}
            <div className="grid grid-cols-[110px_minmax(180px,1fr)_96px_112px_64px_132px] items-center gap-3 px-5 py-2 min-w-[760px] bg-[#FFFFFF] border-b border-[#E5E7EB]">
              <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest">
                Referência
              </span>
              <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest">
                Trabalho · Cliente
              </span>
              <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest">
                Etapa
              </span>
              <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest">
                Responsável
              </span>
              <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest text-center">
                Prazo
              </span>
              <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest">
                Estado
              </span>
            </div>

            <div>
              {urgentes.length === 0 ? (
                <div className="flex items-center justify-center py-12 text-[#9CA3AF] text-[12px]">
                  Sem trabalhos ativos
                </div>
              ) : (
                urgentes.map((o) => (
                  <PriorityRow
                    key={o.id}
                    order={o}
                    onSelect={() => onSelectWork(o.id)}
                  />
                ))
              )}
            </div>
          </div>

          {/* Right column */}
          <div className="space-y-4">
            {/* Activity feed */}
            <div className="bg-white rounded-md shadow-sm overflow-hidden">
              <div className="px-5 py-4 border-b border-[#E5E7EB]">
                <h2 className="text-[13px] font-semibold text-[#1F2937]">
                  Actividade Recente
                </h2>
              </div>
              <div className="divide-y divide-[#E5E7EB]">
                {EVENTS.map((e, i) => (
                  <div key={i} className="flex items-start gap-3 px-4 py-3">
                    <span className={`text-xs mt-0.5 flex-shrink-0 ${e.color}`}>
                      {e.icon}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className="text-[11px] text-[#1F2937] leading-snug">
                        {e.text}
                      </p>
                      <p className="text-[10px] text-[#6B7280] font-mono mt-0.5">
                        {e.time}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Standby */}
            <div className="bg-white rounded-md shadow-sm overflow-hidden">
              <div className="flex items-center justify-between px-5 py-4 border-b border-[#E5E7EB]">
                <h2 className="text-[13px] font-semibold text-orange-700 flex items-center gap-2">
                  <span className="w-1.5 h-1.5 rounded-full bg-orange-400" />
                  Em Standby
                </h2>
                <span className="text-[10px] font-mono text-orange-700">
                  {standbyOrders.length}
                </span>
              </div>
              {standbyOrders.length === 0 ? (
                <p className="px-5 py-4 text-[12px] text-[#9CA3AF]">
                  Nenhum trabalho em standby
                </p>
              ) : (
                standbyOrders.map((o) => {
                  const reason = o.steps.find(
                    (s) => s.status === 'standby',
                  )?.standbyReason
                  return (
                    <div
                      key={o.id}
                      onClick={() => onSelectWork(o.id)}
                      className="px-5 py-3.5 border-b border-[#E5E7EB] last:border-b-0 cursor-pointer hover:bg-slate-50 transition-colors"
                    >
                      <div className="flex items-center justify-between">
                        <span className="text-[11px] font-mono text-[#64748B]">
                          {o.ref}
                        </span>
                        <DeadlineBadge prazo={o.prazo} status={o.status} />
                      </div>
                      <p className="text-[12px] text-[#1F2937] mt-1 truncate">
                        {o.descricao}
                      </p>
                      {reason && (
                        <p className="text-[11px] text-[#64748B] mt-0.5 truncate italic">
                          "{reason}"
                        </p>
                      )}
                    </div>
                  )
                })
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
