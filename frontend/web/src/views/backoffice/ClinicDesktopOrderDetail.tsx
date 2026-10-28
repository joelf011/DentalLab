import ClientConversation from '../../components/ClientConversation'
import OrderTimeline from '../../components/OrderTimeline'
import { getClientEvents, useMockWorkState } from '../../mockWorkStore'
import { useState } from 'react'
import { WORK_ORDERS, type WorkOrder } from '../../data'
import { NatureBadge } from '../../components/ui'

type DetailTab = 'resumo' | 'progresso' | 'informacao' | 'historico'

interface ClinicDesktopOrderDetailProps {
  orderId: string
  clinicId: string
  onBack: () => void
}

const TABS: { id: DetailTab; label: string }[] = [
  { id: 'resumo', label: 'Resumo' },
  { id: 'progresso', label: 'Progresso' },
  { id: 'informacao', label: 'Informação' },
  { id: 'historico', label: 'Histórico' },
]

function getMacroState(status: WorkOrder['status']) {
  if (status === 'concluido') {
    return {
      label: 'Concluído',
      percentage: 100,
      badge: 'text-emerald-800 bg-emerald-50',
      dot: 'bg-emerald-500',
      bar: 'bg-emerald-500',
    }
  }
  if (status === 'por_receber' || status === 'encaminhado') {
    return {
      label: 'Iniciar',
      percentage: 10,
      badge: 'text-slate-700 bg-slate-100',
      dot: 'bg-slate-500',
      bar: 'bg-[#C9A227]',
    }
  }
  return {
    label: 'Processamento',
    percentage: 35,
    badge: 'text-amber-800 bg-amber-50',
    dot: 'bg-amber-500',
    bar: 'bg-[#C9A227]',
  }
}

const UPPER_TEETH = [
  18, 17, 16, 15, 14, 13, 12, 11, 21, 22, 23, 24, 25, 26, 27, 28,
]
const LOWER_TEETH = [
  48, 47, 46, 45, 44, 43, 42, 41, 31, 32, 33, 34, 35, 36, 37, 38,
]

function ToothIllustration({
  tooth,
  selected,
  lower,
}: {
  tooth: number
  selected: boolean
  lower?: boolean
}) {
  const position = tooth % 10
  const type =
    position <= 2
      ? 'incisor'
      : position === 3
        ? 'canine'
        : position <= 5
          ? 'premolar'
          : 'molar'
  const paths = {
    incisor:
      'M9 3 C9 3 10.5 1.5 12 1.5 C13.5 1.5 15 3 15 3 L15.5 18 C19 20 20.5 25 19.5 32 C18.5 39 16 42 12 42 C8 42 5.5 39 4.5 32 C3.5 25 5 20 8.5 18 Z',
    canine:
      'M10 2 C10.5 0.5 13.5 0.5 14 2 L15.5 20 C19 22 20 27 18.5 33 C17 39 14.5 42 12 43 C9.5 42 7 39 5.5 33 C4 27 5 22 8.5 20 Z',
    premolar:
      'M6.5 4 C7 1.5 9 1 10.5 3 L12 15 L13.5 3 C15 1 17 1.5 17.5 4 L16.5 19 C20 21 21 26 19.5 33 C18 39 15.5 42 12 42 C8.5 42 6 39 4.5 33 C3 26 4 21 7.5 19 Z',
    molar:
      'M4 5 C4.5 2 7 1 8.5 4 L10 15 L11 3 C11.5 1 13 1 13.5 3 L14.5 15 L16 4 C17.5 1 20 2 20 5 L18.5 20 C21.5 23 22 28 20.5 34 C19 40 16 42 12 42 C8 42 5 40 3.5 34 C2 28 2.5 23 5.5 20 Z',
  }

  return (
    <div className="flex-1 min-w-0 max-w-9 flex flex-col items-center">
      {!lower && (
        <span
          className={`text-[8px] font-mono mb-1 ${
            selected ? 'text-[#8A6F14] font-semibold' : 'text-[#9CA3AF]'
          }`}
        >
          {tooth}
        </span>
      )}
      <svg
        viewBox="0 0 24 44"
        className="w-full h-11 overflow-visible"
        aria-label={`Dente ${tooth}`}
      >
        <g transform={lower ? 'rotate(180 12 22)' : undefined}>
          <path
            d={paths[type]}
            fill={selected ? '#E7C95D' : '#FFFEF8'}
            stroke={selected ? '#9A7A16' : '#CBD5E1'}
            strokeWidth={selected ? '1.5' : '1.1'}
            strokeLinejoin="round"
          />
          <path
            d={
              type === 'molar'
                ? 'M6.5 25 C9 23 15 23 17.5 25 M7 31 C10 29 14 29 17 31'
                : 'M7.5 26 C10 24.5 14 24.5 16.5 26'
            }
            fill="none"
            stroke={selected ? '#B58F1E' : '#E2E8F0'}
            strokeWidth="0.8"
            strokeLinecap="round"
          />
        </g>
      </svg>
      {lower && (
        <span
          className={`text-[8px] font-mono mt-1 ${
            selected ? 'text-[#8A6F14] font-semibold' : 'text-[#9CA3AF]'
          }`}
        >
          {tooth}
        </span>
      )}
    </div>
  )
}

export function VisualOdontogram({
  selectedTeeth,
}: {
  selectedTeeth: number[]
}) {
  return (
    <div className="rounded-xl border border-[#E5E7EB] bg-gradient-to-b from-[#FFFFFF] to-[#F9FAFB] p-5">
      <div className="flex items-end justify-center gap-0.5">
        {UPPER_TEETH.map((tooth) => (
          <ToothIllustration
            key={tooth}
            tooth={tooth}
            selected={selectedTeeth.includes(tooth)}
          />
        ))}
      </div>
      <div className="flex items-center gap-3 my-3">
        <div className="h-px flex-1 bg-gradient-to-r from-transparent via-[#D1D5DB] to-[#D1D5DB]" />
        <span className="text-[8px] font-mono text-[#9CA3AF] uppercase tracking-widest">
          Linha oclusal
        </span>
        <div className="h-px flex-1 bg-gradient-to-l from-transparent via-[#D1D5DB] to-[#D1D5DB]" />
      </div>
      <div className="flex items-start justify-center gap-0.5">
        {LOWER_TEETH.map((tooth) => (
          <ToothIllustration
            key={tooth}
            tooth={tooth}
            selected={selectedTeeth.includes(tooth)}
            lower
          />
        ))}
      </div>
      <div className="flex items-center justify-between gap-4 mt-5 pt-4 border-t border-[#E5E7EB]">
        <div className="flex items-center gap-2">
          <span className="w-3 h-3 rounded-sm bg-[#E7C95D] border border-[#9A7A16]" />
          <span className="text-[10px] text-[#64748B]">
            Dentes associados ao trabalho
          </span>
        </div>
        <span className="text-[10px] font-mono text-[#8A6F14]">
          {selectedTeeth.length > 0
            ? [...selectedTeeth].sort((a, b) => a - b).join(', ')
            : 'Sem dentes selecionados'}
        </span>
      </div>
    </div>
  )
}

function DataField({
  label,
  value,
  mono,
}: {
  label: string
  value: string | number
  mono?: boolean
}) {
  return (
    <div className="space-y-1">
      <p className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
        {label}
      </p>
      <p
        className={`text-[13px] text-[#1F2937] ${
          mono ? 'font-mono font-semibold' : ''
        }`}
      >
        {value || '—'}
      </p>
    </div>
  )
}

function SummaryCard({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <section className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-6">
      <p className="text-[13px] font-semibold text-[#1F2937] mb-5">{title}</p>
      {children}
    </section>
  )
}

export default function ClinicDesktopOrderDetail({
  orderId,
  clinicId,
  onBack,
}: ClinicDesktopOrderDetailProps) {
  useMockWorkState()
  const [activeTab, setActiveTab] = useState<DetailTab>('resumo')
  const order = WORK_ORDERS.find(
    (item) => item.id === orderId && item.clienteId === clinicId,
  )

  if (!order) {
    return (
      <div className="flex-1 flex items-center justify-center">
        <p className="text-[13px] text-[#64748B]">Encomenda não encontrada.</p>
      </div>
    )
  }

  const macroState = getMacroState(order.status)
  const deadline = new Date(order.prazo).toLocaleDateString('pt-PT', {
    day: '2-digit',
    month: '2-digit',
  })

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="min-w-0">
        <div className="bg-[#FFFFFF] border-b border-[#E5E7EB] px-5 md:px-7 py-5">
          <div className="max-w-[1280px]">
            <button
              onClick={onBack}
              className="inline-flex items-center gap-2 text-[11px] text-[#64748B] hover:text-[#1F2937] transition-colors mb-4"
            >
              <span>←</span>
              Voltar às encomendas
            </button>

            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-5">
              <div className="flex items-center gap-4 min-w-0">
                <div>
                  <p className="text-[10px] font-mono text-[#64748B] uppercase tracking-wider">
                    Encomenda
                  </p>
                  <p className="text-[22px] font-serif text-[#1F2937] mt-0.5">
                    {order.ref}
                  </p>
                </div>
                <span
                  className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono font-medium rounded-md ${macroState.badge}`}
                >
                  <span
                    className={`w-1.5 h-1.5 rounded-full ${macroState.dot}`}
                  />
                  {macroState.label}
                </span>
              </div>

              <div className="flex items-center gap-5 flex-wrap lg:justify-end">
                <div>
                  <p className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
                    Tipo de Trabalho
                  </p>
                  <p className="text-[13px] font-medium text-[#1F2937] mt-0.5">
                    {order.tipoName}
                  </p>
                </div>
                <div className="h-8 w-px bg-[#E5E7EB] hidden sm:block" />
                <span className="text-[12px] font-mono text-[#64748B]">
                  Prazo: {deadline}
                </span>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-[#FFFFFF] border-b border-[#E5E7EB] px-5 md:px-7">
          <nav className="max-w-[1280px] flex items-center gap-8 overflow-x-auto">
            {TABS.map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id)}
                className={`flex-shrink-0 py-4 text-[12px] font-medium border-b-2 transition-colors ${
                  activeTab === tab.id
                    ? 'border-[#C9A227] text-[#8A6F14]'
                    : 'border-transparent text-[#64748B] hover:text-[#1F2937]'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        <div className="px-5 md:px-7 py-7 max-w-[1280px]">
          {activeTab === 'resumo' && (
            <div className="grid grid-cols-1 xl:grid-cols-[minmax(360px,0.8fr)_minmax(0,1.2fr)] gap-5 items-start">
              <SummaryCard title="Detalhes Médicos">
                <div className="grid grid-cols-2 gap-x-8 gap-y-6">
                  <DataField label="Médico" value={order.medico} />
                  <DataField
                    label="Identificação"
                    value={order.identificadorPaciente}
                    mono
                  />
                  <DataField label="Idade" value={`${order.idade} anos`} />
                  <DataField
                    label="Sexo"
                    value={order.sexo === 'M' ? 'Masculino' : 'Feminino'}
                  />
                  <DataField label="Material" value={order.material} />
                  <DataField label="Cor" value={order.cor} />
                  <DataField label="Prazo" value={deadline} mono />
                </div>
              </SummaryCard>

              <SummaryCard title="Descrição e Odontograma">
                <div className="flex items-center gap-2 mb-5">
                  <NatureBadge natureza={order.natureza} />
                  <span className="text-[12px] text-[#475569]">
                    {order.tipoName}
                  </span>
                </div>
                <p className="text-[13px] text-[#475569] leading-relaxed mb-6">
                  {order.descricao}
                </p>
                <VisualOdontogram selectedTeeth={order.dentes} />
              </SummaryCard>
            </div>
          )}

          {activeTab === 'progresso' && (
            <div className="max-w-5xl">
              <SummaryCard title="Progresso da Encomenda">
                <div className="flex items-end justify-between gap-4 mb-8">
                  <div>
                    <p className="text-[10px] font-mono text-[#64748B] uppercase tracking-wider">
                      Estado atual
                    </p>
                    <p className="text-[26px] font-semibold text-[#1F2937] mt-1">
                      {macroState.label}{' '}
                      <span className="text-[#8A6F14]">
                        {macroState.percentage}%
                      </span>
                    </p>
                  </div>
                </div>
                <div className="h-4 w-full bg-[#E5E7EB] rounded-full overflow-hidden shadow-inner">
                  <div
                    className={`h-full rounded-full ${macroState.bar}`}
                    style={{ width: `${macroState.percentage}%` }}
                  />
                </div>
                <div className="flex justify-between mt-3">
                  <span className="text-[10px] text-[#64748B]">
                    Encomenda recebida
                  </span>
                  <span className="text-[10px] text-[#64748B]">Conclusão</span>
                </div>
              </SummaryCard>
            </div>
          )}

          {activeTab === 'informacao' && (
            <div className="max-w-5xl">
              <ClientConversation workId={order.id} clinicId={clinicId} />
            </div>
          )}
          {activeTab === 'historico' && (
            <SummaryCard title="Histórico da Encomenda">
              <OrderTimeline events={getClientEvents(order.id)} />
            </SummaryCard>
          )}
        </div>
      </div>
    </div>
  )
}
