import EntityEditor from '../../components/EntityEditor'
import { setMockClientStatus, useMockWorkState } from '../../mockWorkStore'
import { ConfirmDialog } from '../../components/ui'
import { useState } from 'react'
import { CLIENTES, WORK_ORDERS, type Cliente } from '../../data'
import {
  ClientStatusBadge,
  StatusBadge,
  DeadlineBadge,
  Avatar,
  Btn,
  SearchInput,
  SectionTitle,
  Field,
} from '../../components/ui'

interface Props {
  onSelectWork: (id: string) => void
}

export default function Clientes({ onSelectWork }: Props) {
  useMockWorkState()
  const [creating, setCreating] = useState(false)
  const [selected, setSelected] = useState<Cliente | null>(null)
  const [search, setSearch] = useState('')
  const [filterStatus, setFilterStatus] = useState('')

  const filtered = CLIENTES.filter((c) => {
    const q = search.toLowerCase()
    const matchQ =
      !q ||
      c.name.toLowerCase().includes(q) ||
      c.email.toLowerCase().includes(q) ||
      c.nif.includes(q)
    const matchS = !filterStatus || c.status === filterStatus
    return matchQ && matchS
  })

  if (selected)
    return (
      <ClienteDetail
        cliente={selected}
        onBack={() => setSelected(null)}
        onSelectWork={onSelectWork}
      />
    )

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {creating && (
        <EntityEditor
          kind="client"
          onClose={() => setCreating(false)}
          onSaved={(client) => {
            setCreating(false)
            setSelected(client)
          }}
        />
      )}
      <div className="flex items-center gap-3 px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
        <div className="flex-1 max-w-xs">
          <SearchInput
            value={search}
            onChange={setSearch}
            placeholder="Nome, NIF ou e-mail..."
          />
        </div>
        <select
          value={filterStatus}
          onChange={(e) => setFilterStatus(e.target.value)}
          className="px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[12px] text-[#1F2937] focus:border-[#C9A227]/50 focus:outline-none"
        >
          <option value="">Todos os estados</option>
          <option value="ativo">Ativo</option>
          <option value="suspenso">Suspenso</option>
          <option value="aguarda_validacao">A aguardar validação</option>
        </select>
        <div className="ml-auto">
          <Btn variant="primary" size="sm" onClick={() => setCreating(true)}>
            + Novo Cliente
          </Btn>
        </div>
      </div>

      <div className="flex items-center gap-3 px-5 py-2.5 border-b border-[#E5E7EB] bg-[#FFFFFF] flex-shrink-0">
        <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider flex-1">
          Clínica / Consultório
        </span>
        <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-32 hidden lg:block">
          NIF
        </span>
        <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-24 text-center hidden md:block">
          Trabalhos
        </span>
        <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-36">
          Estado
        </span>
        <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-24 text-right hidden xl:block">
          Desde
        </span>
      </div>

      <div className="flex-1 overflow-y-auto bg-white">
        <div>
          {filtered.map((c) => (
            <div
              key={c.id}
              onClick={() => setSelected(c)}
              className="flex items-center gap-3 px-5 py-4 cursor-pointer hover:bg-slate-50 transition-colors border-b border-[#E5E7EB] last:border-b-0"
            >
              <div className="flex items-center gap-3 flex-1 min-w-0">
                <Avatar name={c.name} size="sm" />
                <div className="min-w-0">
                  <p className="text-[13px] text-[#1F2937] truncate">
                    {c.name}
                  </p>
                  <p className="text-[11px] text-[#64748B] truncate">
                    {c.email} · {c.phone}
                  </p>
                </div>
              </div>
              <div className="w-32 hidden lg:block">
                <span className="text-[11px] font-mono text-[#64748B]">
                  {c.nif}
                </span>
              </div>
              <div className="w-24 text-center hidden md:block">
                <span
                  className={`text-[13px] font-serif ${
                    c.activeWorks > 5 ? 'text-amber-700' : 'text-[#1F2937]'
                  }`}
                >
                  {c.activeWorks}
                </span>
              </div>
              <div className="w-36">
                <ClientStatusBadge status={c.status} />
              </div>
              <div className="w-24 text-right hidden xl:block">
                <span className="text-[11px] font-mono text-[#6B7280]">
                  {new Date(c.registeredAt).toLocaleDateString('pt-PT', {
                    year: 'numeric',
                    month: 'short',
                  })}
                </span>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function ClienteDetail({
  cliente,
  onBack,
  onSelectWork,
}: {
  cliente: Cliente
  onBack: () => void
  onSelectWork: (id: string) => void
}) {
  const [editing, setEditing] = useState(false)
  const [action, setAction] = useState<Cliente['status'] | null>(null)
  const [tab, setTab] = useState('info')
  const works = WORK_ORDERS.filter((w) => w.clienteId === cliente.id)
  const tabs = [
    { id: 'info', label: 'Informação' },
    { id: 'trabalhos', label: `Trabalhos (${works.length})` },
  ]

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {editing && (
        <EntityEditor
          kind="client"
          value={cliente}
          onClose={() => setEditing(false)}
          onSaved={() => setEditing(false)}
        />
      )}
      {action && (
        <ConfirmDialog
          title={
            action === 'suspenso'
              ? 'Suspender cliente'
              : cliente.status === 'aguarda_validacao'
                ? 'Aprovar cliente'
                : 'Reativar cliente'
          }
          message={
            action === 'suspenso'
              ? 'O acesso da clínica ficará suspenso. As encomendas e o histórico serão preservados.'
              : 'A clínica ficará ativa e poderá aceder à plataforma.'
          }
          confirmLabel={action === 'suspenso' ? 'Suspender' : 'Confirmar'}
          danger={action === 'suspenso'}
          onCancel={() => setAction(null)}
          onConfirm={() => {
            setMockClientStatus(cliente.id, action)
            setAction(null)
          }}
        />
      )}
      <div className="flex items-center gap-3 px-7 py-3 border-b border-[#E5E7EB] flex-shrink-0">
        <button
          onClick={onBack}
          className="text-[#64748B] hover:text-[#1F2937] transition-colors flex items-center gap-1 text-[12px]"
        >
          ← Clientes
        </button>
        <span className="text-[#9CA3AF]">/</span>
        <span className="text-[12px] text-[#1F2937]">{cliente.name}</span>
        <div className="ml-auto">
          <ClientStatusBadge status={cliente.status} />
        </div>
      </div>

      <div className="px-7 py-5 border-b border-[#E5E7EB] flex items-start gap-4 flex-shrink-0">
        <Avatar name={cliente.name} size="lg" />
        <div className="flex-1">
          <h1 className="text-[22px] font-serif text-[#1F2937]">
            {cliente.name}
          </h1>
          <p className="text-[12px] text-[#64748B] mt-1">
            {cliente.email} · {cliente.phone}
          </p>
          <p className="text-[11px] text-[#6B7280] mt-0.5">{cliente.address}</p>
        </div>
        <div className="flex items-center gap-2">
          <Btn size="sm" variant="ghost" onClick={() => setEditing(true)}>
            Editar
          </Btn>
          {cliente.status === 'aguarda_validacao' ? (
            <Btn size="sm" variant="primary" onClick={() => setAction('ativo')}>
              Aprovar cliente
            </Btn>
          ) : cliente.status === 'suspenso' ? (
            <Btn size="sm" variant="primary" onClick={() => setAction('ativo')}>
              Reativar
            </Btn>
          ) : (
            <Btn
              size="sm"
              variant="danger"
              onClick={() => setAction('suspenso')}
            >
              Suspender
            </Btn>
          )}
        </div>
      </div>

      <div className="flex items-center border-b border-[#E5E7EB] px-7 flex-shrink-0">
        {tabs.map((t) => (
          <button
            key={t.id}
            onClick={() => setTab(t.id)}
            className={`px-4 py-3 text-[12px] font-medium whitespace-nowrap border-b-2 transition-colors ${
              tab === t.id
                ? 'border-[#C9A227] text-[#C9A227]'
                : 'border-transparent text-[#64748B] hover:text-[#1F2937]'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      <div className="flex-1 overflow-y-auto p-7">
        {tab === 'info' && (
          <div className="max-w-2xl grid grid-cols-2 gap-8">
            <div className="space-y-4">
              <SectionTitle>Dados da Clínica</SectionTitle>
              <Field label="Nome" value={cliente.name} />
              <Field label="NIF" value={cliente.nif} mono />
              <Field label="E-mail" value={cliente.email} />
              <Field label="Telefone" value={cliente.phone} />
              <Field label="Morada" value={cliente.address} />
            </div>
            <div className="space-y-4">
              <SectionTitle>Faturação</SectionTitle>
              <Field label="NIF para faturação" value={cliente.nif} mono />
              <Field label="Morada de faturação" value={cliente.address} />
              <div className="mt-4 p-3 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm">
                <p className="text-[11px] text-[#64748B] font-mono">
                  Faturação gerida em sistema externo certificado.
                </p>
              </div>
            </div>
          </div>
        )}

        {tab === 'trabalhos' && (
          <div className="space-y-1.5 max-w-2xl">
            {works.length === 0 ? (
              <p className="text-[12px] text-[#6B7280]">Sem trabalhos.</p>
            ) : (
              works.map((w) => (
                <div
                  key={w.id}
                  onClick={() => onSelectWork(w.id)}
                  className="flex items-center gap-3 px-4 py-3.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm cursor-pointer hover:border-[#C9A227]/25 transition-colors"
                >
                  <span className="text-[11px] font-mono text-[#64748B] w-[120px] flex-shrink-0">
                    {w.ref}
                  </span>
                  <div className="flex-1 min-w-0">
                    <p className="text-[12px] text-[#1F2937] truncate">
                      {w.descricao}
                    </p>
                    <p className="text-[11px] text-[#64748B] truncate">
                      {w.medico} · {w.identificadorPaciente}
                    </p>
                  </div>
                  <DeadlineBadge prazo={w.prazo} status={w.status} />
                  <StatusBadge status={w.status} stage={w.etapaAtual} />
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  )
}
