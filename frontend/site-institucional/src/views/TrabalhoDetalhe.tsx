import { useState } from 'react'
import { WORK_ORDERS, TIMELINE_EVENTS, NOTES, COLABORADORES, type WorkOrder, type WorkOrderStep, type InternalNote } from '../data'
import { StatusBadge, NatureBadge, DeadlineBadge, Avatar, GoldDivider, SectionTitle, Btn, Modal, Textarea, Select, Field, STEP_STATUS, useToast, WarningBanner, VisibilityBadge, ErrorState } from '../components/ui'
import type { UserRole } from '../data'

// ─── Odontogram ───────────────────────────────────────────────────────────────

const FDI_TEETH = {
  upperRight: [18, 17, 16, 15, 14, 13, 12, 11],
  upperLeft:  [21, 22, 23, 24, 25, 26, 27, 28],
  lowerLeft:  [31, 32, 33, 34, 35, 36, 37, 38],
  lowerRight: [48, 47, 46, 45, 44, 43, 42, 41],
}

function ToothIcon({ n, selected, onClick }: { n: number; selected: boolean; onClick: () => void }) {
  const molar = n % 10 >= 6 || n % 10 === 8
  const premolar = n % 10 >= 4 && n % 10 <= 5
  return (
    <button
      onClick={onClick}
      title={`Dente ${n}`}
      className={`flex flex-col items-center gap-0.5 group transition-all ${selected ? '' : ''}`}
    >
      <span className="text-[8px] font-mono text-[#6B7280] group-hover:text-[#C9A227] transition-colors">{n}</span>
      <svg width={molar ? 22 : premolar ? 18 : 14} height={20} viewBox="0 0 22 22">
        <rect x="2" y="4" width={molar ? 18 : premolar ? 14 : 10} height="16" rx="4"
          className={`transition-all ${selected ? 'fill-[#C9A227] stroke-[#D4AF37]' : 'fill-[#F9FAFB] stroke-[#9CA3AF] group-hover:fill-[#C9A227]/20 group-hover:stroke-[#C9A227]/60'}`}
          strokeWidth="1.5" />
        {molar && <rect x="7" y="8" width="8" height="8" rx="2"
          className={selected ? 'fill-[#1F2937]/30' : 'fill-[#E5E7EB]'} />}
      </svg>
    </button>
  )
}

function Odontogram({ selected, onChange, readOnly }: { selected: number[]; onChange?: (t: number[]) => void; readOnly?: boolean }) {
  const toggle = (n: number) => {
    if (readOnly || !onChange) return
    onChange(selected.includes(n) ? selected.filter(x => x !== n) : [...selected, n])
  }
  const Row = ({ teeth }: { teeth: number[] }) => (
    <div className="flex justify-center gap-0.5">
      {teeth.map(n => <ToothIcon key={n} n={n} selected={selected.includes(n)} onClick={() => toggle(n)} />)}
    </div>
  )

  return (
    <div className="space-y-1 py-3 px-4 bg-[#FFFFFF] rounded-sm border border-[#E5E7EB]">
      <div className="flex justify-center gap-8 mb-1">
        <span className="text-[9px] font-mono text-[#9CA3AF] uppercase">Sup. Direito</span>
        <span className="text-[9px] font-mono text-[#9CA3AF] uppercase">Sup. Esquerdo</span>
      </div>
      <div className="flex justify-center gap-1">
        <Row teeth={FDI_TEETH.upperRight} />
        <div className="w-px bg-[#E5E7EB] self-stretch mx-1" />
        <Row teeth={FDI_TEETH.upperLeft} />
      </div>
      <div className="h-px bg-[#E5E7EB] my-1.5" />
      <div className="flex justify-center gap-1">
        <Row teeth={FDI_TEETH.lowerRight.slice().reverse()} />
        <div className="w-px bg-[#E5E7EB] self-stretch mx-1" />
        <Row teeth={FDI_TEETH.lowerLeft} />
      </div>
      <div className="flex justify-center gap-8 mt-1">
        <span className="text-[9px] font-mono text-[#9CA3AF] uppercase">Inf. Direito</span>
        <span className="text-[9px] font-mono text-[#9CA3AF] uppercase">Inf. Esquerdo</span>
      </div>
      {selected.length > 0 && (
        <p className="text-[11px] text-[#C9A227] font-mono text-center pt-2">
          Dentes intervencionados: {[...selected].sort((a, b) => a - b).join(', ')}
        </p>
      )}
    </div>
  )
}

// ─── Process stepper ──────────────────────────────────────────────────────────

function ProcessStep({ step, isLast }: { step: WorkOrderStep; isLast: boolean }) {
  const cfg = STEP_STATUS[step.status]
  const done = step.status === 'concluida'
  const active = step.status === 'em_execucao'
  const standby = step.status === 'standby'

  return (
    <div className="flex gap-4">
      <div className="flex flex-col items-center">
        <div className={`w-7 h-7 rounded-full border-2 flex items-center justify-center flex-shrink-0 text-[11px] font-mono ${cfg.ring}`}>
          {done ? <span className="text-emerald-700 text-xs">✓</span> : standby ? <span className="text-orange-700 text-xs">⊠</span> : active ? <span className="w-2.5 h-2.5 rounded-full bg-amber-400 animate-pulse" /> : <span className="text-[#6B7280]" />}
        </div>
        {!isLast && <div className={`w-px flex-1 mt-1 ${done ? 'bg-emerald-500/25' : active ? 'bg-amber-400/25' : 'bg-[#E5E7EB]'}`} style={{ minHeight: 24 }} />}
      </div>
      <div className="flex-1 pb-5">
        <div className="flex items-start justify-between gap-2">
          <div>
            <p className={`text-[13px] font-medium ${cfg.color}`}>{step.name}</p>
            {step.collaboratorName && (
              <div className="flex items-center gap-1.5 mt-1">
                <Avatar name={step.collaboratorName} size="xs" />
                <span className="text-[11px] text-[#64748B]">{step.collaboratorName}</span>
              </div>
            )}
          </div>
          <div className="text-right flex-shrink-0">
            {step.startedAt && <p className="text-[10px] font-mono text-[#6B7280]">início: {new Date(step.startedAt).toLocaleDateString('pt-PT')}</p>}
            {step.completedAt && <p className="text-[10px] font-mono text-emerald-700/70">fim: {new Date(step.completedAt).toLocaleDateString('pt-PT')}</p>}
          </div>
        </div>
        {step.standbyReason && (
          <div className="mt-2 px-3 py-2 bg-orange-400/8 border border-orange-400/20 rounded-sm">
            <p className="text-[11px] text-orange-700/80 italic">Motivo: {step.standbyReason}</p>
          </div>
        )}
      </div>
    </div>
  )
}

// ─── Modals ───────────────────────────────────────────────────────────────────

function AcceptWorkModal({ work, onClose, onAccept }: { work: WorkOrder; onClose: () => void; onAccept: (prazo: string) => void }) {
  const [prazo, setPrazo] = useState(work.prazo)
  const [error, setError] = useState('')

  const handleAccept = () => {
    if (!prazo) { setError('O prazo é obrigatório para aceitar o trabalho.'); return }
    onAccept(prazo)
    onClose()
  }

  return (
    <Modal title="Aceitar Trabalho" subtitle={work.ref} onClose={onClose}>
      <div className="p-6 space-y-5">
        <div className="bg-[#FFFFFF] rounded-sm border border-[#E5E7EB] p-4 space-y-2">
          <p className="text-[13px] text-[#1F2937]">{work.descricao}</p>
          <p className="text-[11px] text-[#64748B]">{work.clienteName} · {work.medico}</p>
          <div className="flex gap-2 mt-2">
            <NatureBadge natureza={work.natureza} />
            <span className="text-[11px] font-mono text-[#64748B]">{work.tipoName}</span>
          </div>
        </div>

        <div className="space-y-1">
          <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
            Processo atribuído
          </label>
          <div className="px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm">
            <p className="text-[12px] text-[#1F2937]">Processo Padrão — Prótese Fixa</p>
            <p className="text-[10px] text-[#64748B] font-mono mt-0.5">7 etapas · Receção → Expedição</p>
          </div>
        </div>

        <div className="space-y-1">
          <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
            Prazo de entrega <span className="text-[#C9A227]">*</span>
          </label>
          <input type="date" value={prazo} onChange={e => { setPrazo(e.target.value); setError('') }}
            min={new Date().toISOString().split('T')[0]}
            className="w-full px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] focus:border-[#C9A227]/50 focus:outline-none" />
          {error && <p className="text-[11px] text-red-700 flex items-center gap-1"><span>!</span> {error}</p>}
        </div>

        <div className="flex justify-end gap-2 pt-2">
          <Btn variant="ghost" onClick={onClose}>Cancelar</Btn>
          <Btn variant="primary" onClick={handleAccept}>Aceitar Trabalho</Btn>
        </div>
      </div>
    </Modal>
  )
}

function ReopenWorkModal({ work, onClose, onReopen }: {
  work: WorkOrder
  onClose: () => void
  onReopen: (prazo: string, stepIds: string[]) => void
}) {
  const [prazo, setPrazo] = useState(work.prazo)
  const [reason, setReason] = useState('')
  const [selectedSteps, setSelectedSteps] = useState<string[]>([])
  const [error, setError] = useState('')

  const toggleStep = (stepId: string) => {
    setSelectedSteps(current => current.includes(stepId)
      ? current.filter(id => id !== stepId)
      : [...current, stepId])
    setError('')
  }

  const handleReopen = () => {
    if (!prazo) { setError('Defina o novo prazo de entrega.'); return }
    if (!selectedSteps.length) { setError('Selecione pelo menos uma etapa a reabrir.'); return }
    if (!reason.trim()) { setError('Indique o motivo da reabertura.'); return }
    onReopen(prazo, selectedSteps)
    onClose()
  }

  return (
    <Modal title="Reabrir Trabalho Arquivado" subtitle={work.ref} onClose={onClose}>
      <div className="p-6 space-y-5">
        <div className="px-4 py-3 bg-amber-400/10 border border-amber-400/25 rounded-sm">
          <p className="text-[11px] text-amber-800">O trabalho regressará à produção e as etapas selecionadas serão reiniciadas sem eliminar o histórico existente.</p>
        </div>

        <div className="space-y-2">
          <SectionTitle>Etapas a reabrir</SectionTitle>
          <div className="max-h-48 overflow-y-auto border border-[#E5E7EB] rounded-sm divide-y divide-[#E5E7EB]">
            {work.steps.map(step => (
              <label key={step.id} className="flex items-center gap-3 px-3 py-2.5 bg-[#FFFFFF] cursor-pointer hover:bg-[#F9FAFB]">
                <input
                  type="checkbox"
                  checked={selectedSteps.includes(step.id)}
                  onChange={() => toggleStep(step.id)}
                  className="accent-[#C9A227]"
                />
                <span className="text-[12px] text-[#1F2937]">{step.name}</span>
                <span className="ml-auto text-[9px] font-mono text-[#6B7280]">{STEP_STATUS[step.status].label}</span>
              </label>
            ))}
          </div>
        </div>

        <div className="space-y-1">
          <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">Novo prazo de entrega</label>
          <input
            type="date"
            value={prazo}
            min={new Date().toISOString().split('T')[0]}
            onChange={e => { setPrazo(e.target.value); setError('') }}
            className="w-full px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] focus:border-[#C9A227]/50 focus:outline-none"
          />
        </div>

        <Textarea
          label="Motivo da reabertura"
          value={reason}
          onChange={value => { setReason(value); setError('') }}
          placeholder="Descreva o motivo para registo de auditoria..."
          rows={3}
        />
        {error && <p className="text-[11px] text-red-700">! {error}</p>}

        <div className="flex justify-end gap-2">
          <Btn variant="ghost" onClick={onClose}>Cancelar</Btn>
          <Btn variant="primary" onClick={handleReopen}>Confirmar Reabertura</Btn>
        </div>
      </div>
    </Modal>
  )
}

function AssumeStepModal({ work, onClose, onAssume }: { work: WorkOrder; onClose: () => void; onAssume: (stepId: string) => void }) {
  const [selectedStep, setSelectedStep] = useState('')
  const availableSteps = work.steps.filter(s => s.status === 'nao_iniciado' || s.status === 'standby')

  return (
    <Modal title="Assumir Etapa" subtitle={work.ref} onClose={onClose}>
      <div className="p-6 space-y-5">
        <div className="bg-[#FFFFFF] rounded-sm border border-[#E5E7EB] p-4">
          <p className="text-[13px] text-[#1F2937]">{work.descricao}</p>
          <p className="text-[11px] text-[#64748B] mt-1">{work.clienteName} · Prazo: {new Date(work.prazo).toLocaleDateString('pt-PT')}</p>
        </div>

        <div className="space-y-2">
          <SectionTitle>Etapas disponíveis</SectionTitle>
          {availableSteps.length === 0 ? (
            <p className="text-[12px] text-[#64748B]">Sem etapas disponíveis para assumir.</p>
          ) : availableSteps.map(s => (
            <button key={s.id} onClick={() => setSelectedStep(s.id)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-sm border text-left transition-colors ${selectedStep === s.id ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF] hover:border-[#9CA3AF]'}`}>
              <div className={`w-2 h-2 rounded-full flex-shrink-0 ${selectedStep === s.id ? 'bg-[#C9A227]' : 'bg-[#9CA3AF]'}`} />
              <div>
                <p className="text-[13px] text-[#1F2937]">{s.name}</p>
                {s.status === 'standby' && <p className="text-[10px] text-orange-700 font-mono mt-0.5">Retomar do standby</p>}
              </div>
            </button>
          ))}
        </div>

        <div className="space-y-1">
          <SectionTitle>Colaborador atual</SectionTitle>
          <div className="flex items-center gap-2">
            <Avatar name="Ana Martins" size="xs" />
            <span className="text-[12px] text-[#1F2937]">Ana Martins</span>
            <span className="text-[10px] text-[#64748B] font-mono">— a assumir etapa</span>
          </div>
        </div>

        <div className="px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm">
          <p className="text-[10px] font-mono text-[#6B7280]">Ao confirmar, será registado como responsável e o timestamp de início é marcado automaticamente.</p>
        </div>

        <div className="flex justify-end gap-2">
          <Btn variant="ghost" onClick={onClose}>Cancelar</Btn>
          <Btn variant="primary" disabled={!selectedStep} onClick={() => { onAssume(selectedStep); onClose() }}>Confirmar e Assumir</Btn>
        </div>
      </div>
    </Modal>
  )
}

function CompleteStepModal({ work, onClose, onComplete }: { work: WorkOrder; onClose: () => void; onComplete: (action: string, reason?: string) => void }) {
  const [action, setAction] = useState<'encaminhar' | 'finalizar' | 'standby' | ''>('')
  const [justificacao, setJustificacao] = useState('')
  const [colabDest, setColabDest] = useState('')
  const [error, setError] = useState('')

  const handleConfirm = () => {
    if (!action) { setError('Selecione uma opção.'); return }
    if (action === 'standby' && !justificacao.trim()) { setError('A justificação é obrigatória para standby.'); return }
    onComplete(action, justificacao || undefined)
    onClose()
  }

  return (
    <Modal title="Finalizar Etapa" subtitle={`${work.ref} · ${work.etapaAtual}`} onClose={onClose}>
      <div className="p-6 space-y-5">
        <div className="space-y-2">
          <SectionTitle>Próximo passo</SectionTitle>
          {[
            { id: 'encaminhar', label: 'Encaminhar para outro colaborador', icon: '→', color: 'text-violet-700' },
            { id: 'finalizar', label: 'Finalizar trabalho', icon: '✓', color: 'text-emerald-700' },
            { id: 'standby', label: 'Colocar em standby', icon: '⊠', color: 'text-orange-700' },
          ].map(opt => (
            <button key={opt.id} onClick={() => { setAction(opt.id as typeof action); setError('') }}
              className={`w-full flex items-center gap-3 px-4 py-3.5 rounded-sm border text-left transition-colors ${action === opt.id ? 'border-[#C9A227]/50 bg-[#C9A227]/8' : 'border-[#E5E7EB] bg-[#FFFFFF] hover:border-[#9CA3AF]'}`}>
              <span className={`text-base ${opt.color}`}>{opt.icon}</span>
              <span className="text-[13px] text-[#1F2937]">{opt.label}</span>
            </button>
          ))}
        </div>

        {action === 'encaminhar' && (
          <Select label="Encaminhar para" value={colabDest} onChange={setColabDest}
            options={COLABORADORES.filter(c => c.role !== 'admin').map(c => ({ value: c.id, label: c.name }))} required />
        )}

        {action === 'standby' && (
          <div className="space-y-1">
            <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">
              Justificação <span className="text-[#C9A227]">*</span>
            </label>
            <textarea value={justificacao} onChange={e => { setJustificacao(e.target.value); setError('') }}
              placeholder="Descreva o motivo do standby..."
              rows={3}
              className="w-full px-3 py-2.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none resize-none" />
          </div>
        )}

        {error && <p className="text-[11px] text-red-700 flex items-center gap-1"><span>!</span> {error}</p>}

        <div className="flex justify-end gap-2">
          <Btn variant="ghost" onClick={onClose}>Cancelar</Btn>
          <Btn variant="primary" disabled={!action} onClick={handleConfirm}>Confirmar</Btn>
        </div>
      </div>
    </Modal>
  )
}

// ─── Notes Section ────────────────────────────────────────────────────────────

function NotesSection({ workId, userRole }: { workId: string; userRole: UserRole }) {
  const [notes, setNotes] = useState<InternalNote[]>(NOTES.filter(n => n.workId === workId))
  const [content, setContent] = useState('')
  const [visibility, setVisibility] = useState<'interna' | 'cliente'>('interna')
  const [tab, setTab] = useState<'all' | 'interna' | 'cliente'>('all')

  const add = () => {
    if (!content.trim()) return
    const note: InternalNote = { id: `n${Date.now()}`, workId, content, author: 'Catarina Domingos', date: new Date().toISOString(), visibility }
    setNotes(prev => [note, ...prev])
    setContent('')
  }

  const toggleNoteVisibility = (id: string) => {
    setNotes(prev => prev.map(n => n.id === id ? { ...n, visibility: n.visibility === 'interna' ? 'cliente' : 'interna' } : n))
  }

  const filtered = tab === 'all' ? notes : notes.filter(n => n.visibility === tab)
  const canEdit = userRole === 'admin' || userRole === 'rececionista'

  return (
    <div className="space-y-4">
      {/* Filter tabs */}
      <div className="flex items-center gap-1 border-b border-[#E5E7EB]">
        {([
          { id: 'all', label: 'Todas', count: notes.length },
          { id: 'interna', label: '🔒 Internas', count: notes.filter(n => n.visibility === 'interna').length },
          { id: 'cliente', label: '👁 Visíveis ao cliente', count: notes.filter(n => n.visibility === 'cliente').length },
        ] as const).map(t => (
          <button key={t.id} onClick={() => setTab(t.id)}
            className={`px-3 py-2.5 text-[12px] font-medium border-b-2 transition-colors whitespace-nowrap ${tab === t.id ? 'border-[#C9A227] text-[#C9A227]' : 'border-transparent text-[#64748B] hover:text-[#1F2937]'}`}>
            {t.label}
            <span className="ml-1.5 text-[10px] font-mono opacity-60">{t.count}</span>
          </button>
        ))}
      </div>

      {/* Note list */}
      {filtered.length === 0 ? (
        <p className="text-[12px] text-[#6B7280] py-4">Sem notas nesta categoria.</p>
      ) : filtered.map(n => (
        <div key={n.id}
          className={`p-3.5 rounded-sm border transition-colors ${
            n.visibility === 'cliente'
              ? 'bg-emerald-950/30 border-emerald-500/25 hover:border-emerald-500/40'
              : 'bg-[#FFFFFF] border-[#E5E7EB] hover:border-[#9CA3AF]'
          }`}>
          {/* Visibility indicator + toggle */}
          <div className="flex items-center justify-between gap-2 mb-2">
            <VisibilityBadge
              visibility={n.visibility}
              onChange={canEdit ? () => toggleNoteVisibility(n.id) : undefined}
            />
            {canEdit && (
              <span className="text-[9px] text-[#9CA3AF] font-mono">clique para alterar</span>
            )}
          </div>
          <p className="text-[12px] text-[#1F2937] leading-relaxed">{n.content}</p>
          <div className="flex items-center gap-2 mt-2.5">
            <Avatar name={n.author} size="xs" />
            <span className="text-[10px] text-[#64748B] font-mono">{n.author} · {new Date(n.date).toLocaleDateString('pt-PT', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}</span>
          </div>
        </div>
      ))}

      {/* Add note form */}
      {canEdit && (
        <div className="space-y-2.5 pt-3 border-t border-[#E5E7EB]">
          <textarea value={content} onChange={e => setContent(e.target.value)}
            placeholder="Adicionar nota..."
            rows={2}
            className="w-full px-3 py-2.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[12px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none resize-none" />
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1.5">
              <span className="text-[10px] text-[#6B7280]">Guardar como:</span>
              {(['interna', 'cliente'] as const).map(v => (
                <button key={v} onClick={() => setVisibility(v)}
                  className={`text-[10px] font-mono px-2 py-1 rounded-sm border transition-all ${
                    visibility === v
                      ? v === 'cliente'
                        ? 'border-emerald-500/40 text-emerald-700 bg-emerald-400/10'
                        : 'border-zinc-500/40 text-slate-700 bg-zinc-500/10'
                      : 'border-[#E5E7EB] text-[#64748B] hover:text-[#1F2937]'
                  }`}>
                  {v === 'interna' ? '🔒 Interna' : '👁 Visível ao cliente'}
                </button>
              ))}
            </div>
            <Btn size="sm" variant="primary" onClick={add} disabled={!content.trim()}>Guardar nota</Btn>
          </div>
        </div>
      )}
    </div>
  )
}

// ─── Files Section ────────────────────────────────────────────────────────────

type FileItem = { name: string; visibility: 'interna' | 'cliente'; size?: string }
type FileSection = { label: string; icon: string; visibility: 'interna' | 'cliente'; files: FileItem[] }

function FilesSection({ natureza }: { natureza: 'fisico' | 'digital' }) {
  const [sections, setSections] = useState<FileSection[]>(
    natureza === 'digital'
      ? [
          { label: 'Ficheiros de Trabalho', icon: '⬡', visibility: 'interna', files: [
              { name: 'modelo_superior.stl', visibility: 'interna', size: '4.2 MB' },
              { name: 'modelo_inferior.stl', visibility: 'interna', size: '3.8 MB' },
              { name: 'antagonista.stl', visibility: 'interna', size: '2.1 MB' },
          ]},
          { label: 'Documentos', icon: '⊟', visibility: 'interna', files: [
              { name: 'proposta_DSD_v2.pdf', visibility: 'cliente', size: '1.2 MB' },
              { name: 'instrucoes_tecnicas.pdf', visibility: 'interna', size: '0.4 MB' },
          ]},
          { label: 'Fotografias', icon: '◧', visibility: 'interna', files: [
              { name: 'foto_scan_01.jpg', visibility: 'interna', size: '2.8 MB' },
              { name: 'foto_scan_02.jpg', visibility: 'interna', size: '3.1 MB' },
              { name: 'render_final.jpg', visibility: 'cliente', size: '5.4 MB' },
          ]},
        ]
      : [
          { label: 'Documentos de Entrada', icon: '⊟', visibility: 'interna', files: [
              { name: 'prescricao.pdf', visibility: 'interna', size: '0.8 MB' },
              { name: 'rx_panoramico.jpg', visibility: 'interna', size: '4.5 MB' },
          ]},
          { label: 'Fotografias de Processo', icon: '◧', visibility: 'interna', files: [
              { name: 'foto_impressao_01.jpg', visibility: 'interna', size: '3.2 MB' },
              { name: 'foto_gesso_01.jpg', visibility: 'interna', size: '2.7 MB' },
              { name: 'foto_enceramento_01.jpg', visibility: 'interna', size: '3.1 MB' },
              { name: 'foto_prova_final.jpg', visibility: 'cliente', size: '4.0 MB' },
          ]},
        ]
  )

  const toggleFileVisibility = (sectionLabel: string, fileName: string) => {
    setSections(prev => prev.map(s => s.label !== sectionLabel ? s : {
      ...s,
      files: s.files.map(f => f.name !== fileName ? f : { ...f, visibility: f.visibility === 'interna' ? 'cliente' : 'interna' })
    }))
  }

  const allFiles = sections.flatMap(s => s.files)
  const clientCount = allFiles.filter(f => f.visibility === 'cliente').length
  const totalCount = allFiles.length

  return (
    <div className="space-y-6">
      {/* Summary banner */}
      <div className="flex items-center gap-3 px-4 py-3 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm">
        <div className="flex-1">
          <p className="text-[11px] text-[#475569]">Visibilidade dos ficheiros</p>
          <p className="text-[12px] text-[#1F2937] mt-0.5">
            <span className="text-emerald-700 font-mono">{clientCount}</span> de <span className="font-mono">{totalCount}</span> ficheiros visíveis ao cliente
          </p>
        </div>
        <div className="flex gap-2">
          <span className="inline-flex items-center gap-1 px-2 py-1 text-[10px] font-mono text-emerald-700 bg-emerald-400/10 border border-emerald-400/20 rounded-sm">👁 {clientCount} cliente</span>
          <span className="inline-flex items-center gap-1 px-2 py-1 text-[10px] font-mono text-slate-500 bg-zinc-500/8 border border-zinc-500/15 rounded-sm">🔒 {totalCount - clientCount} interno</span>
        </div>
      </div>

      {sections.map(s => (
        <div key={s.label}>
          <div className="flex items-center gap-2 mb-3">
            <span className="text-sm text-[#64748B]">{s.icon}</span>
            <h4 className="text-[11px] font-mono text-[#64748B] uppercase tracking-wider">{s.label}</h4>
            <span className="text-[9px] font-mono text-[#9CA3AF]">{s.files.length} ficheiros</span>
          </div>

          {s.files.length === 0 ? (
            <div className="border border-dashed border-[#E5E7EB] rounded-sm py-5 flex flex-col items-center gap-2 text-center cursor-pointer hover:border-[#C9A227]/30 transition-colors">
              <span className="text-[#9CA3AF] text-2xl">⊕</span>
              <span className="text-[11px] text-[#6B7280]">Arrastar ficheiros ou clique para carregar</span>
            </div>
          ) : (
            <div className="space-y-1.5">
              {s.files.map(f => {
                const isStl = f.name.endsWith('.stl')
                const isClient = f.visibility === 'cliente'
                return (
                  <div key={f.name}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-sm border transition-colors ${
                      isStl
                        ? 'border-sky-400/25 bg-sky-950/30'
                        : isClient
                          ? 'border-emerald-500/20 bg-emerald-950/20'
                          : 'border-[#E5E7EB] bg-[#FFFFFF]'
                    }`}>
                    <span className={`text-sm flex-shrink-0 ${isStl ? 'text-sky-700' : 'text-[#64748B]'}`}>
                      {isStl ? '⬡' : f.name.endsWith('.pdf') ? '⊟' : '◧'}
                    </span>
                    <div className="flex-1 min-w-0">
                      <p className={`text-[12px] truncate ${isStl ? 'text-sky-700 font-mono' : 'text-[#1F2937]'}`}>{f.name}</p>
                      {f.size && <p className="text-[10px] text-[#6B7280] font-mono">{f.size}</p>}
                    </div>
                    <VisibilityBadge
                      visibility={f.visibility}
                      onChange={() => toggleFileVisibility(s.label, f.name)}
                    />
                    {isStl && <span className="text-[10px] text-sky-700 font-mono bg-sky-400/10 px-1.5 py-0.5 rounded-sm border border-sky-400/20">STL</span>}
                    <button className="text-[#6B7280] hover:text-[#C9A227] transition-colors text-sm flex-shrink-0">⤓</button>
                  </div>
                )
              })}
              <button className="text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors flex items-center gap-1 mt-1">
                + Adicionar ficheiro
              </button>
            </div>
          )}
        </div>
      ))}
    </div>
  )
}

// ─── Main Detail Component ────────────────────────────────────────────────────

interface Props {
  workId: string
  onBack: () => void
  userRole: UserRole
  collaboratorView?: 'inicio' | 'disponiveis' | 'meus' | 'prazos'
}

export default function TrabalhoDetalhe({ workId, onBack, userRole, collaboratorView }: Props) {
  const [work, setWork] = useState<WorkOrder>(WORK_ORDERS.find(w => w.id === workId)!)
  const [activeTab, setActiveTab] = useState('processo')
  const [modal, setModal] = useState<'accept' | 'assume' | 'complete' | 'reopen' | null>(null)
  const [standbyWarningDismissed, setStandbyWarningDismissed] = useState(false)
  const { show, ToastEl } = useToast()

  if (!work) return <ErrorState message="Trabalho não encontrado." />

  const days = Math.ceil((new Date(work.prazo).getTime() - Date.now()) / 86400000)
  const isLate = days < 0
  const isInternalManager = userRole === 'admin' || userRole === 'rececionista'
  const collaboratorCanAssume = userRole === 'colaborador' && collaboratorView === 'disponiveis'
  const collaboratorCanComplete = userRole === 'colaborador' && collaboratorView === 'meus'

  const tabs = [
    { id: 'processo', label: 'Processo' },
    { id: 'odontograma', label: 'Odontograma' },
    { id: 'historico', label: 'Histórico' },
    { id: 'notas', label: 'Notas' },
    { id: 'ficheiros', label: 'Ficheiros' },
  ]

  const events = TIMELINE_EVENTS.filter(e => e.workId === workId)

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      {ToastEl}

      {/* Warning banners */}
      {isLate && (
        <WarningBanner
          message={`Prazo excedido em ${Math.abs(days)} dias — este trabalho necessita de atenção imediata.`}
        />
      )}
      {work.status === 'em_standby' && !standbyWarningDismissed && (
        <WarningBanner
          message="Trabalho em standby — aguarda resolução antes de continuar a produção."
          onDismiss={() => setStandbyWarningDismissed(true)}
        />
      )}

      {/* Header */}
      <div className={`flex-shrink-0 border-b ${isLate ? 'border-b-red-500/40' : 'border-b-[#E5E7EB]'}`}>
        <div className="flex items-center gap-3 px-7 py-3 border-b border-[#E5E7EB]">
          <button onClick={onBack} className="text-[#64748B] hover:text-[#1F2937] transition-colors text-sm flex items-center gap-1">
            ← <span className="text-[12px]">Trabalhos</span>
          </button>
          <span className="text-[#9CA3AF]">/</span>
          <span className="text-[11px] font-mono text-[#C9A227]">{work.ref}</span>
        </div>
        <div className="px-7 py-4 flex items-start gap-4">
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 flex-wrap mb-1">
              <StatusBadge status={work.status} stage={work.etapaAtual} />
              <NatureBadge natureza={work.natureza} />
              <span className="text-[11px] font-mono text-[#64748B]">{work.tipoName}</span>
            </div>
            <h1 className="text-[20px] font-serif text-[#1F2937] leading-tight mt-1">{work.descricao}</h1>
            <p className="text-[12px] text-[#64748B] mt-1">{work.clienteName} · {work.medico} · Paciente: {work.identificadorPaciente}</p>
          </div>
          <div className="flex items-center gap-2 flex-shrink-0 flex-wrap justify-end">
            <DeadlineBadge prazo={work.prazo} />
            {(userRole === 'admin' || userRole === 'rececionista') && work.status === 'por_receber' && (
              <Btn variant="primary" size="sm" onClick={() => setModal('accept')}>Aceitar Trabalho</Btn>
            )}
            {isInternalManager && work.status !== 'concluido' && work.status !== 'por_receber' && (
              <>
                <Btn size="sm" onClick={() => setModal('assume')}>Assumir Etapa</Btn>
                <Btn size="sm" onClick={() => setModal('complete')}>Finalizar Etapa</Btn>
              </>
            )}
            {collaboratorCanAssume && work.status !== 'concluido' && (
              <Btn size="sm" onClick={() => setModal('assume')}>Assumir Etapa</Btn>
            )}
            {collaboratorCanComplete && work.status !== 'concluido' && (
              <Btn size="sm" onClick={() => setModal('complete')}>Finalizar Etapa</Btn>
            )}
            {userRole === 'admin' && (
              <>
                {work.status === 'concluido' && (
                  <Btn size="sm" variant="primary" onClick={() => setModal('reopen')}>Reabrir Trabalho</Btn>
                )}
                <Btn size="sm" variant="ghost">Editar</Btn>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-hidden flex">
        {/* Main content */}
        <div className="flex-1 flex flex-col overflow-hidden">
          {/* Tabs */}
          <div className="flex items-center border-b border-[#E5E7EB] px-7 flex-shrink-0 overflow-x-auto">
            {tabs.map(t => (
              <button key={t.id} onClick={() => setActiveTab(t.id)}
                className={`px-4 py-3 text-[12px] font-medium whitespace-nowrap border-b-2 transition-colors ${activeTab === t.id ? 'border-[#C9A227] text-[#C9A227]' : 'border-transparent text-[#64748B] hover:text-[#1F2937]'}`}>
                {t.label}
              </button>
            ))}
          </div>

          <div className="flex-1 overflow-y-auto p-7">
            {activeTab === 'processo' && (
              <div className="max-w-2xl space-y-0">
                {work.steps.map((step, i) => (
                  <ProcessStep key={step.id} step={step} isLast={i === work.steps.length - 1} />
                ))}
              </div>
            )}

            {activeTab === 'odontograma' && (
              <div className="max-w-lg space-y-4">
                <Odontogram selected={work.dentes} readOnly />
              </div>
            )}

            {activeTab === 'historico' && (
              <div className="max-w-xl space-y-0">
                {events.length === 0 ? (
                  <p className="text-[12px] text-[#6B7280]">Sem eventos registados.</p>
                ) : events.map((e, i) => (
                  <div key={e.id} className="flex gap-4">
                    <div className="flex flex-col items-center">
                      <div className={`w-2 h-2 rounded-full flex-shrink-0 mt-1.5 ${i === 0 ? 'bg-[#C9A227]' : 'bg-[#9CA3AF]'}`} />
                      {i < events.length - 1 && <div className="w-px flex-1 bg-[#E5E7EB] mt-1" />}
                    </div>
                    <div className="pb-4">
                      <p className="text-[12px] text-[#1F2937]">{e.description}</p>
                      <p className="text-[10px] text-[#64748B] font-mono mt-0.5">{e.actor} · {new Date(e.date).toLocaleDateString('pt-PT', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })}</p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {activeTab === 'notas' && <div className="max-w-xl"><NotesSection workId={work.id} userRole={userRole} /></div>}
            {activeTab === 'ficheiros' && <div className="max-w-xl"><FilesSection natureza={work.natureza} /></div>}
          </div>
        </div>

        {/* Right info panel */}
        <div className="w-72 flex-shrink-0 border-l border-[#E5E7EB] overflow-y-auto">
          <div className="p-5 space-y-5">
            <div className="space-y-3">
              <SectionTitle>Dados do Trabalho</SectionTitle>
              <Field label="Cliente" value={work.clienteName} />
              <Field label="Médico responsável" value={work.medico} />
              <Field label="Requisitado por" value={work.requisitadoPor} />
              <Field label="Identificador do Paciente" value={work.identificadorPaciente} mono />
              <Field label="Sexo / Idade" value={`${work.sexo === 'M' ? 'Masculino' : 'Feminino'} · ${work.idade} anos`} />
            </div>

            <GoldDivider />

            <div className="space-y-3">
              <SectionTitle>Especificações</SectionTitle>
              <Field label="Tipo de trabalho" value={work.tipoName} />
              <Field label="Natureza" value={<NatureBadge natureza={work.natureza} />} />
              <Field label="Material" value={work.material} />
              <Field label="Cor" value={work.cor} mono />
            </div>

            <GoldDivider />

            <div className="space-y-3">
              <SectionTitle>Datas</SectionTitle>
              <Field label="Prazo de entrega" value={<DeadlineBadge prazo={work.prazo} />} />
              <Field label="Próxima consulta" value={new Date(work.proximaConsulta).toLocaleDateString('pt-PT')} />
              <Field label="Criado em" value={new Date(work.criadoEm).toLocaleDateString('pt-PT')} />
            </div>

            <GoldDivider />

            <div className="space-y-2">
              <SectionTitle>Responsável</SectionTitle>
              {work.responsavelName ? (
                <div className="flex items-center gap-2">
                  <Avatar name={work.responsavelName} size="sm" />
                  <div>
                    <p className="text-[12px] text-[#1F2937]">{work.responsavelName}</p>
                    <p className="text-[10px] text-[#64748B] font-mono">Etapa: {work.etapaAtual}</p>
                  </div>
                </div>
              ) : <p className="text-[12px] text-[#6B7280]">Não atribuído</p>}
            </div>

            {work.descricao && (
              <>
                <GoldDivider />
                <div>
                  <SectionTitle>Descrição / Obs.</SectionTitle>
                  <p className="text-[12px] text-[#475569] leading-relaxed">{work.descricao}</p>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Modals */}
      {modal === 'accept' && (
        <AcceptWorkModal work={work} onClose={() => setModal(null)}
          onAccept={(prazo) => { setWork(prev => ({ ...prev, prazo, status: 'em_producao' })); show('Trabalho aceite com sucesso') }} />
      )}
      {modal === 'assume' && (
        <AssumeStepModal work={work} onClose={() => setModal(null)}
          onAssume={(_stepId) => { show('Etapa assumida') }} />
      )}
      {modal === 'complete' && (
        <CompleteStepModal work={work} onClose={() => setModal(null)}
          onComplete={(action) => { show(action === 'standby' ? 'Trabalho colocado em standby' : action === 'finalizar' ? 'Trabalho finalizado' : 'Trabalho encaminhado') }} />
      )}
      {modal === 'reopen' && (
        <ReopenWorkModal
          work={work}
          onClose={() => setModal(null)}
          onReopen={(prazo, stepIds) => {
            const firstReopenedStep = work.steps.find(step => stepIds.includes(step.id))
            setWork(prev => ({
              ...prev,
              prazo,
              status: 'em_producao',
              etapaAtual: firstReopenedStep?.name ?? prev.etapaAtual,
              responsavelId: undefined,
              responsavelName: undefined,
              steps: prev.steps.map(step => stepIds.includes(step.id)
                ? {
                    ...step,
                    status: 'nao_iniciado',
                    collaboratorId: undefined,
                    collaboratorName: undefined,
                    startedAt: undefined,
                    completedAt: undefined,
                    standbyReason: undefined,
                  }
                : step),
            }))
            show('Trabalho reaberto e etapas reiniciadas')
          }}
        />
      )}
    </div>
  )
}
