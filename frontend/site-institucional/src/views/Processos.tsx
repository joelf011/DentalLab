import { useState } from 'react'
import { PROCESSES, type Process, type ProcessStep } from '../data'
import { Btn, Toggle, SectionTitle, Input, ConfirmDialog, useToast } from '../components/ui'

export default function Processos() {
  const [processes, setProcesses] = useState<Process[]>(PROCESSES)
  const [selected, setSelected] = useState<Process | null>(null)
  const [editing, setEditing] = useState<Process | null>(null)
  const { show, ToastEl } = useToast()

  const handleDuplicate = (p: Process) => {
    const copy: Process = { ...p, id: `p${Date.now()}`, name: `${p.name} (cópia)`, active: false, steps: p.steps.map(s => ({ ...s, id: `s${Date.now()}_${s.id}` })) }
    setProcesses(prev => [...prev, copy])
    show('Processo duplicado')
  }

  const handleToggleActive = (id: string) => {
    setProcesses(prev => prev.map(p => p.id === id ? { ...p, active: !p.active } : p))
  }

  if (editing) return <ProcessEditor process={editing} onSave={p => { setProcesses(prev => prev.map(x => x.id === p.id ? p : x)); setEditing(null); show('Processo guardado') }} onCancel={() => setEditing(null)} />

  return (
    <div className="flex-1 flex overflow-hidden">
      {ToastEl}

      {/* List */}
      <div className={`flex flex-col ${selected ? 'w-[400px]' : 'w-full'} border-r border-[#E5E7EB] overflow-hidden transition-all`}>
        <div className="flex items-center justify-between px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
          <div>
            <h2 className="text-[14px] font-serif text-[#1F2937]">Processos de Produção</h2>
            <p className="text-[11px] text-[#64748B] mt-0.5">{processes.length} processos configurados</p>
          </div>
          <Btn variant="primary" size="sm" onClick={() => {
            const novo: Process = { id: `p${Date.now()}`, name: 'Novo Processo', active: false, steps: [], workTypes: [] }
            setEditing(novo)
          }}>+ Novo Processo</Btn>
        </div>

        <div className="flex-1 overflow-y-auto divide-y divide-[#E5E7EB]">
          {processes.map(p => (
            <div key={p.id} onClick={() => setSelected(selected?.id === p.id ? null : p)}
              className={`px-5 py-4 cursor-pointer transition-colors border-l-2 ${selected?.id === p.id ? 'bg-[#C9A227]/6 border-l-[#C9A227]' : 'hover:bg-slate-50 border-l-transparent'}`}>
              <div className="flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0">
                  <div className="flex items-center gap-2">
                    <p className="text-[13px] text-[#1F2937] font-medium truncate">{p.name}</p>
                    {!p.active && <span className="text-[9px] font-mono px-1.5 py-0.5 border border-[#E5E7EB] text-[#6B7280] rounded-sm flex-shrink-0">INATIVO</span>}
                  </div>
                  <p className="text-[11px] text-[#64748B] mt-0.5 font-mono">{p.steps.length} etapas</p>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0" onClick={e => e.stopPropagation()}>
                  <Toggle checked={p.active} onChange={() => handleToggleActive(p.id)} />
                  <button onClick={() => setEditing(p)} className="text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors px-2">Editar</button>
                  <button onClick={() => handleDuplicate(p)} className="text-[11px] text-[#64748B] hover:text-[#1F2937] transition-colors px-2">Duplicar</button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Detail */}
      {selected && (
        <div className="flex-1 flex flex-col overflow-hidden">
          <div className="flex items-center justify-between px-7 py-5 border-b border-[#E5E7EB] flex-shrink-0">
            <div>
              <h2 className="text-[18px] font-serif text-[#1F2937]">{selected.name}</h2>
              <p className="text-[11px] text-[#64748B] mt-0.5">{selected.steps.length} etapas · {selected.active ? 'Ativo' : 'Inativo'}</p>
            </div>
            <div className="flex items-center gap-2">
              <Btn size="sm" onClick={() => setEditing(selected)}>Editar</Btn>
              <button onClick={() => setSelected(null)} className="text-[#6B7280] hover:text-[#1F2937] transition-colors text-xl ml-2">×</button>
            </div>
          </div>

          <div className="flex-1 overflow-y-auto p-7">
            <SectionTitle>Etapas do Processo</SectionTitle>
            <div className="space-y-1 max-w-md">
              {selected.steps.map((step, i) => (
                <div key={step.id} className="flex items-center gap-3 px-4 py-3 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm">
                  <span className="text-[11px] font-mono text-[#64748B] w-6 flex-shrink-0">{step.order}</span>
                  <div className="w-px h-4 bg-[#E5E7EB]" />
                  <p className="text-[13px] text-[#1F2937] flex-1">{step.name}</p>
                  {i < selected.steps.length - 1 && (
                    <span className="text-[#9CA3AF] text-xs">↓</span>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function ProcessEditor({ process, onSave, onCancel }: { process: Process; onSave: (p: Process) => void; onCancel: () => void }) {
  const [p, setP] = useState<Process>({ ...process, steps: [...process.steps] })
  const [newStepName, setNewStepName] = useState('')
  const [confirm, setConfirm] = useState<string | null>(null)
  const { show, ToastEl } = useToast()

  const addStep = () => {
    if (!newStepName.trim()) return
    const step: ProcessStep = { id: `s${Date.now()}`, name: newStepName.trim(), order: p.steps.length + 1 }
    setP(prev => ({ ...prev, steps: [...prev.steps, step] }))
    setNewStepName('')
  }

  const removeStep = (id: string) => {
    setP(prev => ({ ...prev, steps: prev.steps.filter(s => s.id !== id).map((s, i) => ({ ...s, order: i + 1 })) }))
  }

  const moveStep = (id: string, dir: 'up' | 'down') => {
    setP(prev => {
      const steps = [...prev.steps]
      const idx = steps.findIndex(s => s.id === id)
      if (dir === 'up' && idx > 0) [steps[idx - 1], steps[idx]] = [steps[idx], steps[idx - 1]]
      if (dir === 'down' && idx < steps.length - 1) [steps[idx], steps[idx + 1]] = [steps[idx + 1], steps[idx]]
      return { ...prev, steps: steps.map((s, i) => ({ ...s, order: i + 1 })) }
    })
  }

  const editStepName = (id: string, name: string) => {
    setP(prev => ({ ...prev, steps: prev.steps.map(s => s.id === id ? { ...s, name } : s) }))
  }

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {ToastEl}
      <div className="flex items-center justify-between px-7 py-4 border-b border-[#E5E7EB] flex-shrink-0">
        <div className="flex items-center gap-3">
          <button onClick={onCancel} className="text-[#64748B] hover:text-[#1F2937] transition-colors text-[12px] flex items-center gap-1">← Processos</button>
          <span className="text-[#9CA3AF]">/</span>
          <span className="text-[12px] text-[#1F2937]">{p.name}</span>
        </div>
        <div className="flex items-center gap-2">
          <Btn variant="ghost" onClick={onCancel}>Cancelar</Btn>
          <Btn variant="primary" onClick={() => { if (!p.name.trim()) { show('Nome obrigatório', 'error'); return }; onSave(p) }}>Guardar</Btn>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto p-7">
        <div className="max-w-xl space-y-8">
          <div className="space-y-4">
            <SectionTitle>Informação do Processo</SectionTitle>
            <Input label="Nome do processo" value={p.name} onChange={v => setP(prev => ({ ...prev, name: v }))} required />
            <Toggle checked={p.active} onChange={v => setP(prev => ({ ...prev, active: v }))} label="Processo ativo" />
          </div>

          <div className="space-y-3">
            <SectionTitle>Etapas ({p.steps.length})</SectionTitle>
            <div className="space-y-1.5">
              {p.steps.map((step, i) => (
                <div key={step.id} className="flex items-center gap-2 px-3 py-2.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm group">
                  <span className="text-[10px] font-mono text-[#6B7280] w-5 flex-shrink-0">{step.order}</span>
                  <input value={step.name} onChange={e => editStepName(step.id, e.target.value)}
                    className="flex-1 bg-transparent text-[13px] text-[#1F2937] focus:outline-none" />
                  <div className="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button onClick={() => moveStep(step.id, 'up')} disabled={i === 0} className="text-[#64748B] hover:text-[#C9A227] disabled:opacity-20 text-xs px-1">↑</button>
                    <button onClick={() => moveStep(step.id, 'down')} disabled={i === p.steps.length - 1} className="text-[#64748B] hover:text-[#C9A227] disabled:opacity-20 text-xs px-1">↓</button>
                    <button onClick={() => setConfirm(step.id)} className="text-[#64748B] hover:text-red-700 text-xs px-1">✕</button>
                  </div>
                </div>
              ))}
            </div>

            <div className="flex items-center gap-2 mt-3">
              <input value={newStepName} onChange={e => setNewStepName(e.target.value)} placeholder="Nome da nova etapa..."
                onKeyDown={e => e.key === 'Enter' && addStep()}
                className="flex-1 px-3 py-2 bg-[#FFFFFF] border border-dashed border-[#9CA3AF] rounded-sm text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none" />
              <Btn size="sm" onClick={addStep} disabled={!newStepName.trim()}>+ Adicionar</Btn>
            </div>
          </div>
        </div>
      </div>

      {confirm && (
        <ConfirmDialog title="Remover etapa" message="Tem a certeza que deseja remover esta etapa do processo?"
          confirmLabel="Remover" danger
          onConfirm={() => { removeStep(confirm); setConfirm(null) }}
          onCancel={() => setConfirm(null)} />
      )}
    </div>
  )
}
