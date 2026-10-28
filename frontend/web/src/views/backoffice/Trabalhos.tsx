import { useState, useMemo } from 'react'
import {
  WORK_ORDERS,
  CLIENTES,
  WORK_TYPES,
  type WorkOrder,
  type WorkStatus,
  type WorkNature,
} from '../../data'
import {
  StatusBadge,
  NatureBadge,
  DeadlineBadge,
  SearchInput,
  Btn,
  Pagination,
  EmptyState,
  SkeletonRow,
  Select,
} from '../../components/ui'
import { useMockWorkState } from '../../mockWorkStore'
import {
  DEADLINE_OPTIONS,
  matchesDeadline,
  type DeadlineFilter,
} from '../../workFilters'
import EditWorkModal, {
  type EditableWorkMetadata,
} from '../../components/EditWorkModal'
import { updateMockWork } from '../../mockWorkStore'
import ClinicDesktopNewOrder from './ClinicDesktopNewOrder'

const PER_PAGE = 8

interface Props {
  onSelectWork: (id: string) => void
  canEdit?: boolean
}

type SortKey = 'prazo' | 'criadoEm' | 'ref' | 'status'
type SortDir = 'asc' | 'desc'

const STATUS_OPTS: { value: string; label: string }[] = [
  { value: '', label: 'Todos os estados' },
  { value: 'por_receber', label: 'Em avaliação' },
  { value: 'encaminhado', label: 'Por iniciar' },
  { value: 'em_producao', label: 'Em processamento' },
  { value: 'em_standby', label: 'Em espera' },
  { value: 'aguarda_aprovacao', label: 'Em prova' },
  { value: 'concluido', label: 'Concluído' },
]

const NAT_OPTS: { value: string; label: string }[] = [
  { value: '', label: 'Todas' },
  { value: 'fisico', label: 'Físico' },
  { value: 'digital', label: 'Digital' },
]

function ColHeader({
  label,
  sortKey,
  currentSort,
  dir,
  onSort,
}: {
  label: string
  sortKey: SortKey
  currentSort: SortKey
  dir: SortDir
  onSort: (k: SortKey) => void
}) {
  const active = currentSort === sortKey
  return (
    <button
      onClick={() => onSort(sortKey)}
      className="flex items-center gap-1 text-[10px] font-mono text-[#6B7280] uppercase tracking-wider hover:text-[#C9A227] transition-colors group"
    >
      {label}
      <span
        className={`text-[8px] ${
          active ? 'text-[#C9A227]' : 'opacity-0 group-hover:opacity-40'
        }`}
      >
        {active && dir === 'asc' ? '↑' : '↓'}
      </span>
    </button>
  )
}

export default function Trabalhos({ onSelectWork, canEdit = false }: Props) {
  const workRevision = useMockWorkState()
  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState<WorkStatus | ''>('')
  const [filterNat, setFilterNat] = useState<WorkNature | ''>('')
  const [filterCliente, setFilterCliente] = useState('')
  const [filterType, setFilterType] = useState('')
  const [filterDeadline, setFilterDeadline] = useState<DeadlineFilter>('')
  const [sortKey, setSortKey] = useState<SortKey>('prazo')
  const [sortDir, setSortDir] = useState<SortDir>('asc')
  const [page, setPage] = useState(1)
  const [showFilters, setShowFilters] = useState(false)
  const [loading] = useState(false)
  const [newOrderOpen, setNewOrderOpen] = useState(false)
  const [editingWork, setEditingWork] = useState<WorkOrder | null>(null)

  const handleSort = (key: SortKey) => {
    if (sortKey === key) setSortDir((prev) => (prev === 'asc' ? 'desc' : 'asc'))
    else {
      setSortKey(key)
      setSortDir('asc')
    }
    setPage(1)
  }

  const filtered = useMemo(() => {
    let data = WORK_ORDERS
    const q = search.toLowerCase()
    if (q)
      data = data.filter(
        (w) =>
          w.ref.toLowerCase().includes(q) ||
          w.identificadorPaciente.toLowerCase().includes(q) ||
          w.clienteName.toLowerCase().includes(q) ||
          w.medico.toLowerCase().includes(q) ||
          w.tipoName.toLowerCase().includes(q) ||
          w.etapaAtual.toLowerCase().includes(q),
      )
    if (filterStatus) data = data.filter((w) => w.status === filterStatus)
    if (filterNat) data = data.filter((w) => w.natureza === filterNat)
    if (filterCliente) data = data.filter((w) => w.clienteId === filterCliente)
    if (filterType) data = data.filter((w) => w.tipoId === filterType)
    if (filterDeadline)
      data = data.filter((w) => matchesDeadline(w, filterDeadline))

    data = [...data].sort((a, b) => {
      let va: string | number = 0,
        vb: string | number = 0
      if (sortKey === 'prazo') {
        va = new Date(a.prazo).getTime()
        vb = new Date(b.prazo).getTime()
      }
      if (sortKey === 'criadoEm') {
        va = new Date(a.criadoEm).getTime()
        vb = new Date(b.criadoEm).getTime()
      }
      if (sortKey === 'ref') {
        va = a.ref
        vb = b.ref
      }
      if (sortKey === 'status') {
        va = a.status
        vb = b.status
      }
      if (va < vb) return sortDir === 'asc' ? -1 : 1
      if (va > vb) return sortDir === 'asc' ? 1 : -1
      return 0
    })
    return data
  }, [
    search,
    filterStatus,
    filterNat,
    filterCliente,
    filterType,
    filterDeadline,
    sortKey,
    sortDir,
    workRevision,
  ])

  if (newOrderOpen)
    return (
      <ClinicDesktopNewOrder
        admin
        onCancel={() => setNewOrderOpen(false)}
        onDone={() => setNewOrderOpen(false)}
      />
    )

  const paged = filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE)
  const activeFilters = [
    filterStatus,
    filterNat,
    filterCliente,
    filterType,
    filterDeadline,
  ].filter(Boolean).length

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {/* Toolbar */}
      <div className="flex items-center gap-3 px-4 md:px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0 flex-wrap gap-y-2">
        <div className="flex-1 min-w-36 max-w-xs">
          <SearchInput
            value={search}
            onChange={(v) => {
              setSearch(v)
              setPage(1)
            }}
            placeholder="Pesquisar trabalhos..."
          />
        </div>
        <button
          onClick={() => setShowFilters((f) => !f)}
          className={`flex items-center gap-1.5 px-3 py-2 text-[12px] border rounded-sm transition-colors ${
            showFilters || activeFilters > 0
              ? 'border-[#C9A227]/40 text-[#C9A227] bg-[#C9A227]/8'
              : 'border-[#E5E7EB] text-[#475569] hover:text-[#1F2937] hover:border-[#9CA3AF]'
          }`}
        >
          ⊟ Filtros{' '}
          {activeFilters > 0 && (
            <span className="bg-[#C9A227] text-[#1F2937] text-[9px] font-bold w-4 h-4 rounded-full flex items-center justify-center">
              {activeFilters}
            </span>
          )}
        </button>
        <div className="ml-auto">
          <Btn
            variant="primary"
            size="sm"
            onClick={() => setNewOrderOpen(true)}
          >
            + Nova Encomenda
          </Btn>
        </div>
      </div>

      {/* Filters */}
      {showFilters && (
        <div className="flex items-center gap-3 px-7 py-3 border-b border-[#E5E7EB] bg-[#FFFFFF] flex-shrink-0 flex-wrap gap-y-2">
          <select
            value={filterStatus}
            onChange={(e) => {
              setFilterStatus(e.target.value as WorkStatus | '')
              setPage(1)
            }}
            className="px-3 py-1.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[12px] text-[#1F2937] focus:border-[#C9A227]/50 focus:outline-none"
          >
            {STATUS_OPTS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
          <select
            value={filterNat}
            onChange={(e) => {
              setFilterNat(e.target.value as WorkNature | '')
              setPage(1)
            }}
            className="px-3 py-1.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[12px] text-[#1F2937] focus:border-[#C9A227]/50 focus:outline-none"
          >
            {NAT_OPTS.map((o) => (
              <option key={o.value} value={o.value}>
                {o.label}
              </option>
            ))}
          </select>
          <select
            value={filterCliente}
            onChange={(e) => {
              setFilterCliente(e.target.value)
              setPage(1)
            }}
            className="px-3 py-1.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[12px] text-[#1F2937] focus:border-[#C9A227]/50 focus:outline-none"
          >
            <option value="">Todos os clientes</option>
            {CLIENTES.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>
          <Select
            label="Tipo"
            value={filterType}
            onChange={(value) => {
              setFilterType(value)
              setPage(1)
            }}
            options={[
              { value: '', label: 'Todos os tipos' },
              ...WORK_TYPES.map((type) => ({
                value: type.id,
                label: type.name,
              })),
            ]}
          />
          <Select
            label="Prazo"
            value={filterDeadline}
            onChange={(value) => {
              setFilterDeadline(value as DeadlineFilter)
              setPage(1)
            }}
            options={DEADLINE_OPTIONS}
          />
          {activeFilters > 0 && (
            <button
              onClick={() => {
                setFilterStatus('')
                setFilterNat('')
                setFilterCliente('')
                setFilterType('')
                setFilterDeadline('')
                setPage(1)
              }}
              className="text-[11px] text-[#64748B] hover:text-red-700 transition-colors"
            >
              ✕ Limpar filtros
            </button>
          )}
          <span className="ml-auto text-[11px] text-[#64748B] font-mono">
            {filtered.length} resultado{filtered.length !== 1 ? 's' : ''}
          </span>
        </div>
      )}

      {/* Table */}
      <div className="flex-1 overflow-y-auto bg-white">
        {loading ? (
          <div className="divide-y divide-[#E5E7EB]">
            {Array.from({ length: 6 }).map((_, i) => (
              <SkeletonRow key={i} />
            ))}
          </div>
        ) : (
          <>
            {/* Desktop header — hidden on narrow screens */}
            <div className="hidden md:flex items-center gap-2 px-5 py-2.5 border-b border-[#E5E7EB] bg-[#FFFFFF] sticky top-0 z-10">
              <div className="w-[110px] flex-shrink-0">
                <ColHeader
                  label="Nº"
                  sortKey="ref"
                  currentSort={sortKey}
                  dir={sortDir}
                  onSort={handleSort}
                />
              </div>
              <div className="flex-1 min-w-0 grid grid-cols-3 gap-2">
                <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
                  Cliente · Médico
                </span>
                <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
                  Identificador
                </span>
                <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
                  Tipo · Natureza
                </span>
              </div>
              <div className="w-[130px] flex-shrink-0 hidden lg:block">
                <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
                  Etapa atual
                </span>
              </div>
              <div className="w-[110px] flex-shrink-0 hidden xl:block">
                <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
                  Responsável
                </span>
              </div>
              <div className="w-20 flex-shrink-0">
                <ColHeader
                  label="Prazo"
                  sortKey="prazo"
                  currentSort={sortKey}
                  dir={sortDir}
                  onSort={handleSort}
                />
              </div>
              <div className="w-[130px] flex-shrink-0">
                <ColHeader
                  label="Estado"
                  sortKey="status"
                  currentSort={sortKey}
                  dir={sortDir}
                  onSort={handleSort}
                />
              </div>
              <div className="w-[90px] flex-shrink-0 hidden xl:block">
                <ColHeader
                  label="Criado"
                  sortKey="criadoEm"
                  currentSort={sortKey}
                  dir={sortDir}
                  onSort={handleSort}
                />
              </div>
              {canEdit && (
                <div className="w-16 flex-shrink-0 text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
                  Ações
                </div>
              )}
            </div>

            {paged.length === 0 ? (
              <EmptyState
                icon="⊞"
                title="Sem resultados"
                description="Nenhum trabalho corresponde aos filtros actuais. Tente ajustar a pesquisa ou filtros."
              />
            ) : (
              <>
                {/* Desktop rows */}
                <div className="hidden md:block">
                  {paged.map((order) => (
                    <WorkRow
                      key={order.id}
                      order={order}
                      onSelect={() => onSelectWork(order.id)}
                      onEdit={canEdit ? () => setEditingWork(order) : undefined}
                    />
                  ))}
                </div>
                {/* Mobile cards — shown below md */}
                <div className="md:hidden">
                  {paged.map((order) => (
                    <WorkCard
                      key={order.id}
                      order={order}
                      onSelect={() => onSelectWork(order.id)}
                    />
                  ))}
                </div>
              </>
            )}

            <Pagination
              page={page}
              total={filtered.length}
              perPage={PER_PAGE}
              onChange={setPage}
            />
          </>
        )}
      </div>

      {editingWork && (
        <EditWorkModal
          work={editingWork}
          onClose={() => setEditingWork(null)}
          onSave={(metadata: EditableWorkMetadata) => {
            updateMockWork(editingWork.id, (work) => ({ ...work, ...metadata }))
            setEditingWork(null)
          }}
        />
      )}
    </div>
  )
}

function WorkCard({
  order,
  onSelect,
}: {
  order: WorkOrder
  onSelect: () => void
}) {
  return (
    <div
      onClick={onSelect}
      className="flex gap-3 px-4 py-3.5 cursor-pointer hover:bg-slate-50 transition-colors border-b border-[#E5E7EB] last:border-b-0"
    >
      <div className="flex-1 min-w-0 space-y-1.5">
        <div className="flex items-center gap-2 flex-wrap">
          <span className="text-[10px] font-mono text-[#64748B]">
            {order.ref}
          </span>
          <StatusBadge status={order.status} stage={order.etapaAtual} />
          <NatureBadge natureza={order.natureza} />
        </div>
        <p className="text-[13px] text-[#1F2937] font-mono font-medium truncate">
          {order.identificadorPaciente}
        </p>
        <p className="text-[11px] text-[#475569] truncate">
          {order.clienteName} · {order.medico}
        </p>
        <p className="text-[11px] text-[#64748B]">
          {order.tipoName} · {order.etapaAtual}
        </p>
      </div>
      <div className="flex flex-col items-end justify-between flex-shrink-0">
        <DeadlineBadge prazo={order.prazo} status={order.status} />
        <span className="text-[#6B7280] text-sm mt-2">›</span>
      </div>
    </div>
  )
}

function WorkRow({
  order,
  onSelect,
  onEdit,
}: {
  order: WorkOrder
  onSelect: () => void
  onEdit?: () => void
}) {
  const days = Math.ceil(
    (new Date(order.prazo).getTime() - Date.now()) / 86400000,
  )
  const isLate = order.status !== 'concluido' && days < 0
  const isUrgent = order.status !== 'concluido' && !isLate && days <= 2
  const rowBg = isLate
    ? 'bg-red-500/4 hover:bg-red-500/7'
    : isUrgent
      ? 'bg-orange-400/4 hover:bg-orange-400/7'
      : 'hover:bg-slate-50'
  return (
    <div
      onClick={onSelect}
      className={`flex items-center gap-2 px-5 py-3 cursor-pointer transition-colors border-b border-[#E5E7EB] last:border-b-0 ${rowBg}`}
    >
      <div className="w-[110px] flex-shrink-0">
        <span className="text-[11px] font-mono text-[#64748B]">
          {order.ref}
        </span>
      </div>
      <div className="flex-1 min-w-0 grid grid-cols-3 gap-2">
        <div className="min-w-0">
          <p className="text-[12px] text-[#1F2937] truncate">
            {order.clienteName}
          </p>
          <p className="text-[11px] text-[#64748B] truncate">{order.medico}</p>
        </div>
        <div className="min-w-0">
          <p className="text-[12px] text-[#1F2937] font-mono truncate">
            {order.identificadorPaciente}
          </p>
          <p className="text-[11px] text-[#64748B] truncate font-mono">
            {order.sexo} · {order.idade}a
          </p>
        </div>
        <div className="flex items-center gap-1.5 flex-wrap">
          <NatureBadge natureza={order.natureza} />
          <span className="text-[11px] text-[#475569]">{order.tipoName}</span>
        </div>
      </div>
      <div className="w-[130px] flex-shrink-0 hidden lg:block">
        <p className="text-[11px] text-[#475569] truncate">
          {order.etapaAtual}
        </p>
      </div>
      <div className="w-[110px] flex-shrink-0 hidden xl:block">
        {order.responsavelName ? (
          <p className="text-[11px] text-[#475569] truncate">
            {order.responsavelName.split(' ')[0]}
          </p>
        ) : (
          <span className="text-[11px] text-[#9CA3AF]">—</span>
        )}
      </div>
      <div className="w-20 flex-shrink-0">
        <DeadlineBadge prazo={order.prazo} status={order.status} />
      </div>
      <div className="w-[130px] flex-shrink-0">
        <StatusBadge status={order.status} stage={order.etapaAtual} />
      </div>
      <div className="w-[90px] flex-shrink-0 hidden xl:block">
        <span className="text-[11px] font-mono text-[#6B7280]">
          {new Date(order.criadoEm).toLocaleDateString('pt-PT', {
            day: '2-digit',
            month: 'short',
          })}
        </span>
      </div>
      {onEdit && (
        <div className="w-16 flex-shrink-0">
          <button
            type="button"
            onClick={(event) => {
              event.stopPropagation()
              onEdit()
            }}
            className="min-h-9 px-2 text-[11px] font-semibold text-[var(--gold-ink)] hover:underline"
          >
            Editar
          </button>
        </div>
      )}
    </div>
  )
}
