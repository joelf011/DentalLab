import { useState } from 'react'
import { WORK_TYPES, PROCESSES, type WorkType } from '../data'
import { Btn, NatureBadge, SectionTitle, Input, Select, ConfirmDialog, useToast } from '../components/ui'

export default function TiposTrabalho() {
  const [types, setTypes] = useState<WorkType[]>(WORK_TYPES)
  const [editing, setEditing] = useState<WorkType | null>(null)
  const [confirm, setConfirm] = useState<string | null>(null)
  const { show, ToastEl } = useToast()

  const save = (t: WorkType) => {
    if (types.find(x => x.id === t.id)) {
      setTypes(prev => prev.map(x => x.id === t.id ? t : x))
    } else {
      setTypes(prev => [...prev, t])
    }
    setEditing(null)
    show('Tipo de trabalho guardado')
  }

  const remove = (id: string) => {
    setTypes(prev => prev.filter(t => t.id !== id))
    setConfirm(null)
    show('Tipo removido', 'warning')
  }

  const newType = (): WorkType => ({ id: `wt${Date.now()}`, name: '', nature: 'fisico' })

  return (
    <div className="flex-1 flex overflow-hidden">
      {ToastEl}

      {/* List */}
      <div className={`flex flex-col ${editing ? 'w-[440px] border-r border-[#E5E7EB]' : 'w-full'} overflow-hidden`}>
        <div className="flex items-center justify-between px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
          <div>
            <h2 className="text-[14px] font-serif text-[#1F2937]">Tipos de Trabalho</h2>
            <p className="text-[11px] text-[#64748B] mt-0.5">{types.length} tipos configurados</p>
          </div>
          <Btn variant="primary" size="sm" onClick={() => setEditing(newType())}>+ Novo Tipo</Btn>
        </div>

        <div className="flex items-center gap-3 px-5 py-2.5 border-b border-[#E5E7EB] bg-[#FFFFFF] flex-shrink-0">
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider flex-1">Nome</span>
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-24">Natureza</span>
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider flex-1">Processo padrão</span>
          <span className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider w-20"></span>
        </div>

        <div className="flex-1 overflow-y-auto divide-y divide-[#E5E7EB]">
          {types.map(t => {
            const proc = PROCESSES.find(p => p.id === t.processId)
            const isEditing = editing?.id === t.id
            return (
              <div key={t.id} className={`flex items-center gap-3 px-5 py-4 transition-colors border-l-2 ${isEditing ? 'bg-[#C9A227]/6 border-l-[#C9A227]' : 'border-l-transparent hover:bg-slate-50'}`}>
                <p className="text-[13px] text-[#1F2937] flex-1">{t.name}</p>
                <div className="w-24"><NatureBadge natureza={t.nature} /></div>
                <p className="text-[12px] text-[#64748B] flex-1 truncate">{proc?.name ?? <span className="text-[#9CA3AF]">— nenhum</span>}</p>
                <div className="w-20 flex items-center gap-2 justify-end">
                  <button onClick={() => setEditing(t)} className="text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors">Editar</button>
                  <button onClick={() => setConfirm(t.id)} className="text-[11px] text-[#64748B] hover:text-red-700 transition-colors">✕</button>
                </div>
              </div>
            )
          })}
        </div>
      </div>

      {/* Editor */}
      {editing && (
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
            <h3 className="text-[14px] font-serif text-[#1F2937]">{editing.name || 'Novo Tipo de Trabalho'}</h3>
            <div className="flex items-center gap-2">
              <Btn variant="ghost" onClick={() => setEditing(null)}>Cancelar</Btn>
              <Btn variant="primary" onClick={() => { if (!editing.name.trim()) { show('Nome obrigatório', 'error'); return }; save(editing) }}>Guardar</Btn>
            </div>
          </div>

          <div className="flex-1 overflow-y-auto p-7">
            <div className="max-w-md space-y-5">
              <Input label="Nome do tipo" value={editing.name} onChange={v => setEditing(prev => prev ? { ...prev, name: v } : null!)} required />

              <div className="space-y-2">
                <SectionTitle>Natureza</SectionTitle>
                <div className="flex items-center gap-3">
                  {(['fisico', 'digital'] as const).map(n => (
                    <button key={n} onClick={() => setEditing(prev => prev ? { ...prev, nature: n } : null!)}
                      className={`flex-1 flex items-center gap-2 px-4 py-3 rounded-sm border transition-colors ${editing.nature === n ? 'border-[#C9A227]/50 bg-[#C9A227]/8 text-[#C9A227]' : 'border-[#E5E7EB] bg-[#FFFFFF] text-[#64748B] hover:border-[#9CA3AF]'}`}>
                      <span>{n === 'fisico' ? '◈' : '⬡'}</span>
                      <span className="text-[13px]">{n === 'fisico' ? 'Físico' : 'Digital'}</span>
                    </button>
                  ))}
                </div>
              </div>

              <Select
                label="Processo padrão (opcional)"
                value={editing.processId ?? ''}
                onChange={v => setEditing(prev => prev ? { ...prev, processId: v || undefined } : null!)}
                options={PROCESSES.map(p => ({ value: p.id, label: p.name }))}
              />

              <div className="p-3 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm">
                <p className="text-[11px] text-[#64748B]">O processo padrão é sugerido automaticamente ao criar um trabalho deste tipo. O utilizador pode sempre selecionar outro processo.</p>
              </div>
            </div>
          </div>
        </div>
      )}

      {confirm && (
        <ConfirmDialog title="Remover tipo de trabalho" message="Esta ação não pode ser desfeita. Trabalhos existentes deste tipo não serão afetados."
          confirmLabel="Remover" danger onConfirm={() => remove(confirm)} onCancel={() => setConfirm(null)} />
      )}
    </div>
  )
}
