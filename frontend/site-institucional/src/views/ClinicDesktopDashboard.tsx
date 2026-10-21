import { useEffect, useState } from 'react'
import type { User, WorkOrder } from '../data'
import { CLIENTES, getWorkOrders, subscribeLabData } from '../data'
import { NatureBadge } from '../components/ui'
import ClinicDesktopNewOrder from './ClinicDesktopNewOrder'
import ClinicDesktopOrderDetail from './ClinicDesktopOrderDetail'

export type ClinicDesktopView = 'inicio' | 'encomendas' | 'alertas' | 'conta'

interface ClinicDesktopDashboardProps {
  user: User
  activeView: ClinicDesktopView
  onViewChange: (view: ClinicDesktopView) => void
}

function getMacroProgress(status: WorkOrder['status']) {
  if (status === 'concluido') {
    return { label: 'Concluído', percentage: 100, color: 'bg-emerald-500', textColor: 'text-emerald-800' }
  }
  if (status === 'por_receber' || status === 'encaminhado') {
    return { label: 'Iniciar', percentage: 33, color: 'bg-[#C9A227]', textColor: 'text-slate-700' }
  }
  return { label: 'Processamento', percentage: 66, color: 'bg-[#C9A227]', textColor: 'text-amber-800' }
}

function NeutralDeadline({ deadline }: { deadline: string }) {
  return (
    <span className="text-[11px] font-mono text-[#64748B]">
      Prazo: {new Date(deadline).toLocaleDateString('pt-PT', { day: '2-digit', month: '2-digit' })}
    </span>
  )
}

function OrderCard({ order, onSelect }: { order: WorkOrder; onSelect: () => void }) {
  const progress = getMacroProgress(order.status)

  return (
    <button
      onClick={onSelect}
      className="w-full text-left bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-4 overflow-hidden hover:border-[#C9A227]/40 hover:shadow-sm transition-all"
    >
      <div className="flex items-start justify-between gap-4 mb-2">
        <div className="min-w-0">
          <p className="text-[10px] font-mono text-[#64748B]">{order.ref}</p>
          <p className="text-[13px] font-mono font-medium text-[#1F2937] mt-0.5 leading-snug">{order.identificadorPaciente}</p>
        </div>
        <NeutralDeadline deadline={order.prazo} />
      </div>

      <div className="flex items-center gap-2 flex-wrap">
        <NatureBadge natureza={order.natureza} />
        <span className="text-[11px] text-[#475569]">{order.tipoName}</span>
      </div>

      <div className="mt-2.5 pt-2.5 border-t border-[#E5E7EB]">
        <div className="flex items-center justify-between gap-3">
          <span className="text-[10px] text-[#64748B]">Progresso da encomenda</span>
          <span className={`text-[11px] font-semibold ${progress.textColor}`}>{progress.label}</span>
        </div>
        <div className="h-1.5 w-full bg-[#E5E7EB] rounded-full overflow-hidden mt-2.5">
          <div
            className={`h-full rounded-full ${progress.color} transition-all duration-500`}
            style={{ width: `${progress.percentage}%` }}
          />
        </div>
      </div>
    </button>
  )
}

export default function ClinicDesktopDashboard({
  user,
  activeView,
  onViewChange,
}: ClinicDesktopDashboardProps) {
  const [creatingOrder, setCreatingOrder] = useState(false)
  const [selectedOrderId, setSelectedOrderId] = useState<string | null>(null)
  const [workOrders, setWorkOrders] = useState<WorkOrder[]>(getWorkOrders())
  const clinic = CLIENTES.find(item => item.email === user.email)
  const clinicWorks = workOrders.filter(order => order.clienteId === clinic?.id)
  const recentOrders = clinicWorks.slice(0, 6)
  const starting = clinicWorks.filter(
    order => order.status === 'por_receber' || order.status === 'encaminhado',
  ).length
  const processing = clinicWorks.filter(
    order =>
      order.status === 'em_producao' ||
      order.status === 'em_standby' ||
      order.status === 'aguarda_aprovacao',
  ).length
  const completed = clinicWorks.filter(order => order.status === 'concluido').length

  useEffect(() => {
    setSelectedOrderId(null)
  }, [activeView])

  useEffect(() => {
    const unsubscribe = subscribeLabData(() => {
      setWorkOrders([...getWorkOrders()])
    })
    return unsubscribe
  }, [])

  if (selectedOrderId && clinic) {
    return (
      <ClinicDesktopOrderDetail
        orderId={selectedOrderId}
        clinicId={clinic.id}
        onBack={() => setSelectedOrderId(null)}
      />
    )
  }

  if (creatingOrder && activeView === 'inicio') {
    return (
      <ClinicDesktopNewOrder
        onCancel={() => setCreatingOrder(false)}
        onDone={() => {
          setCreatingOrder(false)
          onViewChange('encomendas')
        }}
      />
    )
  }

  if (activeView === 'encomendas') {
    return (
      <div className="flex-1 overflow-y-auto">
        <div className="p-4 md:p-7 max-w-[1100px] space-y-5">
          <div>
            <p className="text-[22px] font-serif text-[#1F2937]">Encomendas</p>
            <p className="text-[12px] text-[#64748B] mt-1">Acompanhe o progresso das suas encomendas.</p>
          </div>
          <div className="space-y-2.5">
            {clinicWorks.map(order => (
              <OrderCard
                key={order.id}
                order={order}
                onSelect={() => setSelectedOrderId(order.id)}
              />
            ))}
          </div>
        </div>
      </div>
    )
  }

  if (activeView === 'alertas') {
    return (
      <div className="flex-1 overflow-y-auto">
        <div className="p-4 md:p-7 max-w-[1100px] space-y-5">
          <div>
            <p className="text-[22px] font-serif text-[#1F2937]">Alertas</p>
            <p className="text-[12px] text-[#64748B] mt-1">Atualizações sobre as suas encomendas.</p>
          </div>
          <div className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-5">
            <p className="text-[13px] text-[#1F2937]">Uma encomenda está em processamento.</p>
            <p className="text-[11px] text-[#64748B] mt-1">Consulte o progresso na área de encomendas.</p>
          </div>
        </div>
      </div>
    )
  }

  if (activeView === 'conta') {
    return (
      <div className="flex-1 overflow-y-auto">
        <div className="p-4 md:p-7 max-w-[1100px] space-y-5">
          <div>
            <p className="text-[22px] font-serif text-[#1F2937]">Conta</p>
            <p className="text-[12px] text-[#64748B] mt-1">Dados da clínica.</p>
          </div>
          <div className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl overflow-hidden">
            {[
              { label: 'Clínica', value: clinic?.name },
              { label: 'E-mail', value: clinic?.email },
              { label: 'Telefone', value: clinic?.phone },
              { label: 'NIF', value: clinic?.nif },
              { label: 'Morada', value: clinic?.address },
            ].map((field, index) => (
              <div
                key={field.label}
                className={`grid grid-cols-[110px_1fr] gap-4 px-5 py-4 ${
                  index > 0 ? 'border-t border-[#E5E7EB]' : ''
                }`}
              >
                <span className="text-[10px] font-mono text-[#6B7280] uppercase">{field.label}</span>
                <span className="text-[13px] text-[#1F2937]">{field.value ?? '—'}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="p-4 md:p-7 max-w-[1100px] space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <p className="text-[24px] font-serif text-[#1F2937] leading-tight">
              Olá, {clinic?.name ?? user.name}
            </p>
            <p className="text-[12px] text-[#64748B] mt-1">Acompanhe as suas encomendas.</p>
          </div>
          <button
            onClick={() => setCreatingOrder(true)}
            className="inline-flex items-center justify-center self-start sm:self-auto gap-2 px-4 py-2.5 bg-[#C9A227] text-[#1F2937] rounded-md text-[13px] font-semibold hover:bg-[#D4AF37] active:opacity-90 transition-all shadow-sm whitespace-nowrap"
          >
            <span className="text-[17px] font-medium leading-none">+</span>
            Nova Encomenda
          </button>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {[
            {
              label: 'Iniciar',
              value: starting,
              color: 'text-slate-700',
              background: 'bg-slate-100 border-slate-200',
            },
            {
              label: 'Processamento',
              value: processing,
              color: 'text-amber-800',
              background: 'bg-amber-50 border-amber-100',
            },
            {
              label: 'Concluído',
              value: completed,
              color: 'text-emerald-800',
              background: 'bg-emerald-50 border-emerald-100',
            },
          ].map(summary => (
            <button
              key={summary.label}
              onClick={() => onViewChange('encomendas')}
              className={`flex flex-col gap-1.5 p-4 rounded-xl border text-left hover:shadow-sm active:opacity-80 transition-all ${summary.background}`}
            >
              <p className={`text-[28px] font-serif leading-none ${summary.color}`}>{summary.value}</p>
              <p className="text-[11px] text-[#475569]">{summary.label}</p>
            </button>
          ))}
        </div>

        <div>
          <div className="flex items-center justify-between mb-3">
            <p className="text-[14px] font-semibold text-[#1F2937]">Encomendas Recentes</p>
            <button
              onClick={() => onViewChange('encomendas')}
              className="text-[12px] text-[#C9A227] hover:text-[#8A6F14] transition-colors"
            >
              Ver todas →
            </button>
          </div>
          <div className="space-y-2.5">
            {recentOrders.map(order => (
              <OrderCard
                key={order.id}
                order={order}
                onSelect={() => setSelectedOrderId(order.id)}
              />
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
