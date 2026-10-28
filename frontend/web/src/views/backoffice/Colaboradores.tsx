import EntityEditor from '../../components/EntityEditor'
import { setMockCollaboratorAbsent } from '../../mockWorkStore'
import { useState } from 'react'
import { COLABORADORES, WORK_ORDERS, type Colaborador } from '../../data'
import {
  Avatar,
  Btn,
  RoleBadge,
  SearchInput,
  SectionTitle,
  Field,
  StatusBadge,
  DeadlineBadge,
  COLAB_STATUS,
  ConfirmDialog,
  useToast,
} from '../../components/ui'
import {
  softDeleteMockCollaborator,
  useMockWorkState,
} from '../../mockWorkStore'

interface Props {
  onSelectWork: (id: string) => void
}

export default function Colaboradores({ onSelectWork }: Props) {
  useMockWorkState()
  const [creating, setCreating] = useState(false)
  const [selected, setSelected] = useState<Colaborador | null>(null)
  const [search, setSearch] = useState('')

  const filtered = COLABORADORES.filter(
    (c) =>
      !c.deletedAt &&
      (!search ||
        c.name.toLowerCase().includes(search.toLowerCase()) ||
        c.role.includes(search.toLowerCase())),
  )

  if (selected)
    return (
      <ColabDetail
        colab={selected}
        onBack={() => setSelected(null)}
        onDeleted={() => setSelected(null)}
        onSelectWork={onSelectWork}
      />
    )

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {creating && (
        <EntityEditor
          kind="collaborator"
          onClose={() => setCreating(false)}
          onSaved={(person) => {
            setCreating(false)
            setSelected(person)
          }}
        />
      )}
      <div className="flex items-center gap-3 px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
        <div className="flex-1 max-w-xs">
          <SearchInput
            value={search}
            onChange={setSearch}
            placeholder="Nome, função..."
          />
        </div>
        <div className="ml-auto">
          <Btn variant="primary" size="sm" onClick={() => setCreating(true)}>
            + Novo Colaborador
          </Btn>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-7">
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.map((c) => {
            const colabStatus = COLAB_STATUS[c.status]
            const dotColor =
              c.status === 'disponivel'
                ? 'bg-emerald-400'
                : c.status === 'ocupado'
                  ? 'bg-amber-400'
                  : 'bg-zinc-500'
            return (
              <div
                key={c.id}
                onClick={() => setSelected(c)}
                className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm p-5 cursor-pointer hover:border-[#C9A227]/25 transition-colors"
              >
                <div className="flex items-start justify-between mb-4">
                  <Avatar name={c.name} size="md" />
                  <RoleBadge role={c.role} />
                </div>
                <h3 className="text-[14px] font-medium text-[#1F2937]">
                  {c.name}
                </h3>

                <div className="flex items-center gap-1.5 mt-2">
                  <span className={`w-1.5 h-1.5 rounded-full ${dotColor}`} />
                  <span className="text-[10px] text-[#64748B] font-mono">
                    {colabStatus.label}
                  </span>
                </div>
                <div className="mt-4 pt-4 border-t border-[#E5E7EB] grid grid-cols-2 gap-2">
                  <div>
                    <p className="text-[9px] font-mono text-[#6B7280] uppercase tracking-wider">
                      Ativos
                    </p>
                    <p
                      className={`text-[22px] font-serif mt-0.5 ${
                        c.activeWorks > 2 ? 'text-amber-700' : 'text-[#1F2937]'
                      }`}
                    >
                      {c.activeWorks}
                    </p>
                  </div>
                  <div>
                    <p className="text-[9px] font-mono text-[#6B7280] uppercase tracking-wider">
                      Conc. mês
                    </p>
                    <p className="text-[22px] font-serif mt-0.5 text-emerald-700">
                      {c.completedThisMonth}
                    </p>
                  </div>
                </div>
              </div>
            )
          })}
        </div>
      </div>
    </div>
  )
}

function ColabDetail({
  colab,
  onBack,
  onDeleted,
  onSelectWork,
}: {
  colab: Colaborador
  onBack: () => void
  onDeleted: () => void
  onSelectWork: (id: string) => void
}) {
  const [editing, setEditing] = useState(false)
  const [confirmAbsence, setConfirmAbsence] = useState(false)
  const [tab, setTab] = useState('info')
  const [confirmDelete, setConfirmDelete] = useState(false)
  const { show, ToastEl } = useToast()
  const works = WORK_ORDERS.filter((w) => w.responsavelId === colab.id)
  const activeWorks = works.filter((w) => w.status !== 'concluido')
  const colabStatus = COLAB_STATUS[colab.status]
  const dotColor =
    colab.status === 'disponivel'
      ? 'bg-emerald-400'
      : colab.status === 'ocupado'
        ? 'bg-amber-400'
        : 'bg-zinc-500'

  const tabs = [
    { id: 'info', label: 'Perfil' },
    { id: 'trabalhos', label: `Trabalhos Ativos (${activeWorks.length})` },
    { id: 'permissoes', label: 'Permissões' },
  ]

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {ToastEl}
      {editing && (
        <EntityEditor
          kind="collaborator"
          value={colab}
          onClose={() => setEditing(false)}
          onSaved={() => setEditing(false)}
        />
      )}
      {confirmAbsence && (
        <ConfirmDialog
          title={
            colab.status === 'ausente' ? 'Marcar disponível' : 'Marcar ausente'
          }
          message={
            colab.status === 'ausente'
              ? 'O colaborador poderá voltar a receber novas etapas.'
              : 'O colaborador não receberá novas atribuições. As tarefas atuais mantêm-se atribuídas.'
          }
          onCancel={() => setConfirmAbsence(false)}
          onConfirm={() => {
            setMockCollaboratorAbsent(colab.id, colab.status !== 'ausente')
            setConfirmAbsence(false)
          }}
        />
      )}
      <div className="flex items-center gap-3 px-7 py-3 border-b border-[#E5E7EB] flex-shrink-0">
        <button
          onClick={onBack}
          className="text-[#64748B] hover:text-[#1F2937] transition-colors flex items-center gap-1 text-[12px]"
        >
          ← Colaboradores
        </button>
        <span className="text-[#9CA3AF]">/</span>
        <span className="text-[12px] text-[#1F2937]">{colab.name}</span>
      </div>

      <div className="px-7 py-5 border-b border-[#E5E7EB] flex items-start gap-4 flex-shrink-0">
        <Avatar name={colab.name} size="lg" />
        <div className="flex-1">
          <div className="flex items-center gap-2 mb-1">
            <h1 className="text-[22px] font-serif text-[#1F2937]">
              {colab.name}
            </h1>
            <RoleBadge role={colab.role} />
          </div>
          <p className="text-[12px] text-[#64748B]">{colab.email}</p>
          <div className="flex items-center gap-1.5 mt-1.5">
            <span className={`w-1.5 h-1.5 rounded-full ${dotColor}`} />
            <span className="text-[11px] text-[#64748B] font-mono">
              {colabStatus.label}
            </span>
          </div>
        </div>
        <div className="flex items-center gap-2">
          <Btn size="sm" variant="ghost" onClick={() => setEditing(true)}>
            Editar
          </Btn>
          {colab.role !== 'admin' && (
            <>
              {colab.status === 'ausente' ? (
                <Btn
                  size="sm"
                  variant="primary"
                  onClick={() => setConfirmAbsence(true)}
                >
                  Marcar Disponível
                </Btn>
              ) : (
                <Btn
                  size="sm"
                  variant="secondary"
                  onClick={() => setConfirmAbsence(true)}
                >
                  Marcar Ausente
                </Btn>
              )}
              <Btn
                size="sm"
                variant="danger"
                onClick={() => setConfirmDelete(true)}
              >
                Eliminar colaborador
              </Btn>
            </>
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
          <div className="max-w-xl grid grid-cols-2 gap-6">
            <div className="space-y-4">
              <SectionTitle>Dados Pessoais</SectionTitle>
              <Field label="Nome completo" value={colab.name} />
              <Field label="E-mail" value={colab.email} />
              <Field
                label="Membro desde"
                value={new Date(colab.joinedAt).toLocaleDateString('pt-PT', {
                  year: 'numeric',
                  month: 'long',
                })}
              />
            </div>
            <div className="space-y-4">
              <SectionTitle>Desempenho — mês atual</SectionTitle>
              <div className="space-y-3">
                <div>
                  <p className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider mb-1">
                    Trabalhos concluídos
                  </p>
                  <p className="text-[36px] font-serif text-emerald-700 leading-none">
                    {colab.completedThisMonth}
                  </p>
                </div>
                <div>
                  <p className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider mb-1">
                    Trabalhos ativos
                  </p>
                  <p
                    className={`text-[36px] font-serif leading-none ${
                      colab.activeWorks > 2
                        ? 'text-amber-700'
                        : 'text-[#1F2937]'
                    }`}
                  >
                    {colab.activeWorks}
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {tab === 'trabalhos' && (
          <div className="max-w-2xl space-y-1.5">
            {activeWorks.length === 0 ? (
              <p className="text-[12px] text-[#6B7280]">
                Sem trabalhos ativos.
              </p>
            ) : (
              activeWorks.map((w) => (
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
                      {w.clienteName} · {w.etapaAtual}
                    </p>
                  </div>
                  <DeadlineBadge prazo={w.prazo} status={w.status} />
                  <StatusBadge status={w.status} stage={w.etapaAtual} />
                </div>
              ))
            )}
          </div>
        )}

        {tab === 'permissoes' && (
          <div className="max-w-md space-y-4">
            <SectionTitle>Função e Acesso</SectionTitle>
            <div className="space-y-2">
              {[
                {
                  role: 'admin',
                  label: 'Administrador',
                  desc: 'Acesso total à plataforma. Gerir clientes, colaboradores, configurações e todos os trabalhos.',
                },
                {
                  role: 'colaborador',
                  label: 'Colaborador',
                  desc: 'Pode ver e assumir trabalhos, executar etapas, adicionar notas e fotografias.',
                },
              ].map((opt) => (
                <div
                  key={opt.role}
                  onClick={() => {}}
                  className={`flex items-start gap-3 p-4 rounded-sm border cursor-pointer transition-colors ${
                    colab.role === opt.role
                      ? 'border-[#C9A227]/40 bg-[#C9A227]/6'
                      : 'border-[#E5E7EB] bg-[#FFFFFF] hover:border-[#9CA3AF]'
                  }`}
                >
                  <div
                    className={`w-4 h-4 rounded-full border-2 flex items-center justify-center flex-shrink-0 mt-0.5 ${
                      colab.role === opt.role
                        ? 'border-[#C9A227]'
                        : 'border-[#6B7280]'
                    }`}
                  >
                    {colab.role === opt.role && (
                      <span className="w-2 h-2 rounded-full bg-[#C9A227]" />
                    )}
                  </div>
                  <div>
                    <p className="text-[13px] text-[#1F2937] font-medium">
                      {opt.label}
                    </p>
                    <p className="text-[11px] text-[#64748B] mt-0.5 leading-relaxed">
                      {opt.desc}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
      {confirmDelete && (
        <ConfirmDialog
          title="Eliminar colaborador"
          message={
            activeWorks.length > 0
              ? 'Este colaborador tem atribuições ativas. Reatribua-as antes de o eliminar.'
              : 'O colaborador deixará de aparecer nas listas e futuras atribuições. O histórico será preservado.'
          }
          confirmLabel="Eliminar"
          danger
          onConfirm={() => {
            try {
              softDeleteMockCollaborator(colab.id)
              onDeleted()
            } catch (error) {
              setConfirmDelete(false)
              show(
                error instanceof Error
                  ? error.message
                  : 'Não foi possível eliminar o colaborador.',
                'error',
              )
            }
          }}
          onCancel={() => setConfirmDelete(false)}
        />
      )}
    </div>
  )
}
