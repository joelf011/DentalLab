import { useState } from 'react'
import { WORK_TYPES, PROCESSES, type WorkType } from '../../data'
import {
  Btn,
  NatureBadge,
  SectionTitle,
  Input,
  Select,
  ConfirmDialog,
  useToast,
} from '../../components/ui'

export default function TiposTrabalho() {
  const [types, setTypes] = useState<WorkType[]>(WORK_TYPES)
  const [editing, setEditing] = useState<WorkType | null>(null)
  const [confirm, setConfirm] = useState<string | null>(null)
  const { show, ToastEl } = useToast()

  const save = (t: WorkType) => {
    if (types.find((x) => x.id === t.id)) {
      setTypes((prev) => prev.map((x) => (x.id === t.id ? t : x)))
    } else {
      setTypes((prev) => [...prev, t])
    }
    setEditing(null)
    show('Tipo de trabalho guardado')
  }

  const remove = (id: string) => {
    setTypes((prev) => prev.filter((t) => t.id !== id))
    setConfirm(null)
    show('Tipo removido', 'warning')
  }

  const newType = (): WorkType => ({
    id: `wt${Date.now()}`,
    name: '',
    nature: 'fisico',
  })

  return (
    <div className="flex-1 flex overflow-hidden">
      {ToastEl}

      {/* List */}
      <div
        className={`flex flex-col ${editing ? 'w-[440px] border-r border-[#E5E7EB]' : 'w-full'} overflow-y-auto`}
      >
        <div className="flex items-center justify-between px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
          <div>
            <h2 className="text-[14px] font-serif text-[#1F2937]">
              Tipos de Trabalho
            </h2>
            <p className="text-[11px] text-[#64748B] mt-0.5">
              {types.length} tipos configurados
            </p>
          </div>
          <Btn
            variant="primary"
            size="sm"
            onClick={() => setEditing(newType())}
          >
            + Novo Tipo
          </Btn>
        </div>

        <div className="flex items-center gap-3 px-5 py-2.5 border-b border-[#E5E7EB] bg-[#FFFFFF] flex-shrink-0">
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider flex-1">
            Nome
          </span>
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-24">
            Natureza
          </span>
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider flex-1">
            Processo padrão
          </span>
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-20"></span>
        </div>

        <div className="divide-y divide-[#E5E7EB]">
          {types.map((t) => {
            const proc = PROCESSES.find((p) => p.id === t.processId)
            const isEditing = editing?.id === t.id
            return (
              <div
                key={t.id}
                className={`flex items-center gap-3 px-5 py-4 transition-colors border-l-2 ${isEditing ? 'bg-[#C9A227]/6 border-l-[#C9A227]' : 'border-l-transparent hover:bg-slate-50'}`}
              >
                <p className="text-[13px] text-[#1F2937] flex-1">{t.name}</p>
                <div className="w-24">
                  <NatureBadge natureza={t.nature} />
                </div>
                <p className="text-[12px] text-[#64748B] flex-1 truncate">
                  {proc?.name ?? (
                    <span className="text-[#9CA3AF]">— nenhum</span>
                  )}
                </p>
                <div className="w-20 flex items-center gap-2 justify-end">
                  <button
                    onClick={() => setEditing(t)}
                    className="text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors"
                  >
                    Editar
                  </button>
                  <button
                    onClick={() => setConfirm(t.id)}
                    className="text-[11px] text-[#64748B] hover:text-red-700 transition-colors"
                  >
                    ✕
                  </button>
                </div>
              </div>
            )
          })}
        </div>

        {!editing && (
          <section className="border-t border-[var(--line)] bg-[var(--paper)] p-7">
            <div className="mb-4">
              <h2 className="text-[14px] font-bold text-[var(--ink)]">
                Etapas de Produção
              </h2>
              <p className="mt-1 text-[11px] text-[var(--muted)]">
                Sequências aplicadas aos tipos de trabalho configurados acima
              </p>
            </div>
            <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
              {PROCESSES.map((process) => (
                <article
                  key={process.id}
                  className="rounded-xl border border-[var(--line)] bg-[var(--surface)] p-5 shadow-sm"
                >
                  <div className="mb-4 flex items-start justify-between gap-3">
                    <div>
                      <h3 className="text-[13px] font-semibold text-[var(--ink)]">
                        {process.name}
                      </h3>
                      <p className="mt-0.5 text-[10px] text-[var(--muted)]">
                        {process.steps.length} etapas sequenciais
                      </p>
                    </div>
                    <span
                      className={`rounded-full px-2 py-1 text-[9px] font-bold uppercase ${process.active ? 'bg-[var(--badge-success-bg)] text-[var(--badge-success-text)]' : 'bg-[var(--soft)] text-[var(--muted)]'}`}
                    >
                      {process.active ? 'Ativo' : 'Inativo'}
                    </span>
                  </div>
                  <ol className="flex flex-wrap gap-2">
                    {process.steps.map((step) => (
                      <li
                        key={step.id}
                        className="flex items-center gap-2 rounded-md border border-[var(--line)] bg-[var(--soft)] px-2.5 py-2 text-[11px] text-[var(--ink)]"
                      >
                        <span className="font-mono font-bold text-[var(--gold-ink)]">
                          {step.order}
                        </span>
                        {step.name}
                      </li>
                    ))}
                  </ol>
                </article>
              ))}
            </div>
          </section>
        )}
      </div>

      {/* Editor */}
      {editing && (
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
            <h3 className="text-[14px] font-serif text-[#1F2937]">
              {editing.name || 'Novo Tipo de Trabalho'}
            </h3>
            <div className="flex items-center gap-2">
              <Btn variant="ghost" onClick={() => setEditing(null)}>
                Cancelar
              </Btn>
              <Btn
                variant="primary"
                onClick={() => {
                  if (!editing.name.trim()) {
                    show('Nome obrigatório', 'error')
                    return
                  }
                  save(editing)
                }}
              >
                Guardar
              </Btn>
            </div>
          </div>

          <div className="flex-1 overflow-y-auto p-7">
            <div className="max-w-md space-y-5">
              <Input
                label="Nome do tipo"
                value={editing.name}
                onChange={(v) =>
                  setEditing((prev) => (prev ? { ...prev, name: v } : null!))
                }
                required
              />

              <div className="space-y-2">
                <SectionTitle>Natureza</SectionTitle>
                <div className="flex items-center gap-3">
                  {(['fisico', 'digital'] as const).map((n) => (
                    <button
                      key={n}
                      onClick={() =>
                        setEditing((prev) =>
                          prev ? { ...prev, nature: n } : null!,
                        )
                      }
                      className={`flex-1 flex items-center gap-2 px-4 py-3 rounded-sm border transition-colors ${editing.nature === n ? 'border-[#C9A227]/50 bg-[#C9A227]/8 text-[#C9A227]' : 'border-[#E5E7EB] bg-[#FFFFFF] text-[#64748B] hover:border-[#9CA3AF]'}`}
                    >
                      <span>{n === 'fisico' ? '◈' : '⬡'}</span>
                      <span className="text-[13px]">
                        {n === 'fisico' ? 'Físico' : 'Digital'}
                      </span>
                    </button>
                  ))}
                </div>
              </div>

              <Select
                label="Processo padrão (opcional)"
                value={editing.processId ?? ''}
                onChange={(v) =>
                  setEditing((prev) =>
                    prev ? { ...prev, processId: v || undefined } : null!,
                  )
                }
                options={PROCESSES.map((p) => ({ value: p.id, label: p.name }))}
              />

              <div className="p-3 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm">
                <p className="text-[11px] text-[#64748B]">
                  O processo padrão é sugerido automaticamente ao criar um
                  trabalho deste tipo. O utilizador pode sempre selecionar outro
                  processo.
                </p>
              </div>
            </div>
          </div>
        </div>
      )}

      {confirm && (
        <ConfirmDialog
          title="Remover tipo de trabalho"
          message="Esta ação não pode ser desfeita. Trabalhos existentes deste tipo não serão afetados."
          confirmLabel="Remover"
          danger
          onConfirm={() => remove(confirm)}
          onCancel={() => setConfirm(null)}
        />
      )}
    </div>
  )
}
