import { type ReactNode, useState } from 'react'
import type { WorkStatus, StepStatus, ClientStatus, ColabStatus, WorkNature, UserRole } from '../data'

// ─── Status configs ────────────────────────────────────────────────────────────

export const WORK_STATUS: Record<WorkStatus, { label: string; color: string; dot: string }> = {
  por_receber:      { label: 'Em avaliação',       color: 'text-sky-800 bg-sky-50',          dot: 'bg-sky-500' },
  encaminhado:      { label: 'Por iniciar',        color: 'text-slate-700 bg-slate-100',     dot: 'bg-slate-500' },
  em_producao:      { label: 'Em processamento',   color: 'text-amber-800 bg-amber-50',      dot: 'bg-amber-500' },
  em_standby:       { label: 'Em espera',          color: 'text-orange-800 bg-orange-50',    dot: 'bg-orange-500' },
  aguarda_aprovacao:{ label: 'Em prova',           color: 'text-violet-800 bg-violet-50',    dot: 'bg-violet-500' },
  concluido:        { label: 'Concluído',          color: 'text-emerald-800 bg-emerald-50',  dot: 'bg-emerald-500' },
}

const CLINIC_ORDER_STATUS: Record<WorkStatus, { label: string; color: string; dot: string }> = {
  por_receber:       { label: 'Iniciar',       color: 'text-slate-700 bg-slate-100',    dot: 'bg-slate-500' },
  encaminhado:       { label: 'Iniciar',       color: 'text-slate-700 bg-slate-100',    dot: 'bg-slate-500' },
  em_producao:       { label: 'Processamento', color: 'text-amber-800 bg-amber-50',     dot: 'bg-amber-500' },
  em_standby:        { label: 'Processamento', color: 'text-amber-800 bg-amber-50',     dot: 'bg-amber-500' },
  aguarda_aprovacao: { label: 'Processamento', color: 'text-amber-800 bg-amber-50',     dot: 'bg-amber-500' },
  concluido:         { label: 'Concluido',     color: 'text-emerald-800 bg-emerald-50', dot: 'bg-emerald-500' },
}

export const STEP_STATUS: Record<StepStatus, { label: string; color: string; ring: string }> = {
  nao_iniciado: { label: 'Não iniciado', color: 'text-slate-500',   ring: 'border-slate-300 bg-[#FFFFFF]' },
  em_execucao:  { label: 'Em execução',  color: 'text-amber-700',  ring: 'border-amber-400 bg-amber-400/10' },
  concluida:    { label: 'Concluída',    color: 'text-emerald-700', ring: 'border-emerald-500 bg-emerald-500/10' },
  standby:      { label: 'Standby',      color: 'text-orange-700',  ring: 'border-orange-400 bg-orange-400/10' },
  cancelada:    { label: 'Cancelada',    color: 'text-red-700',     ring: 'border-red-500 bg-red-500/10' },
}

export const CLIENT_STATUS: Record<ClientStatus, { label: string; color: string; dot: string }> = {
  ativo:              { label: 'Ativo',                color: 'text-emerald-800 bg-emerald-50', dot: 'bg-emerald-500' },
  suspenso:           { label: 'Suspenso',             color: 'text-red-800 bg-red-50',         dot: 'bg-red-500' },
  aguarda_validacao:  { label: 'A aguardar validação', color: 'text-amber-800 bg-amber-50',      dot: 'bg-amber-500' },
}

export const NATURE_CONFIG: Record<WorkNature, { label: string; icon: string; color: string }> = {
  fisico:  { label: 'Físico',  icon: '◈', color: 'text-slate-700 bg-slate-100' },
  digital: { label: 'Digital', icon: '⬡', color: 'text-sky-800 bg-sky-50' },
}

export const ROLE_CONFIG: Record<UserRole, { label: string; color: string }> = {
  admin:        { label: 'Administrador', color: 'text-slate-700 bg-slate-100 border-slate-200' },
  colaborador:  { label: 'Colaborador',  color: 'text-slate-700 bg-zinc-300/10 border-zinc-300/20' },
  rececionista: { label: 'Rececionista', color: 'text-sky-700 bg-sky-400/10 border-sky-400/20' },
  clinica:       { label: 'Clínica',      color: 'text-amber-700 bg-amber-400/10 border-amber-400/20' },
}

export const COLAB_STATUS: Record<ColabStatus, { label: string; dot: string }> = {
  disponivel: { label: 'Disponível', dot: 'bg-emerald-400' },
  ocupado:    { label: 'Ocupado',    dot: 'bg-amber-400' },
  ausente:    { label: 'Ausente',    dot: 'bg-zinc-500' },
}

// ─── Primitive components ──────────────────────────────────────────────────────

export function StatusBadge({ status, audience = 'internal', stage }: { status: WorkStatus; audience?: 'internal' | 'clinic'; stage?: string }) {
  const baseConfig = audience === 'clinic' ? CLINIC_ORDER_STATUS[status] : WORK_STATUS[status]
  const cfg = audience === 'internal' && status === 'concluido' && stage?.toLowerCase() === 'entregue'
    ? { label: 'Entregue', color: 'text-teal-800 bg-teal-50', dot: 'bg-teal-500' }
    : baseConfig
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono font-medium rounded-md whitespace-nowrap ${cfg.color}`}>
      <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${cfg.dot}`} />
      {cfg.label}
    </span>
  )
}

export function NatureBadge({ natureza }: { natureza: WorkNature }) {
  const cfg = NATURE_CONFIG[natureza]
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-1 text-[10px] font-mono font-medium rounded-md ${cfg.color}`}>
      {cfg.icon} {cfg.label}
    </span>
  )
}

export function RoleBadge({ role }: { role: UserRole }) {
  const cfg = ROLE_CONFIG[role]
  return <span className={`inline-flex items-center px-2 py-0.5 text-[10px] font-mono border rounded-sm ${cfg.color}`}>{cfg.label}</span>
}

export function ClientStatusBadge({ status }: { status: ClientStatus }) {
  const cfg = CLIENT_STATUS[status]
  return (
    <span className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono font-medium rounded-md ${cfg.color}`}>
      <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
      {cfg.label}
    </span>
  )
}

export function Avatar({ name, size = 'sm' }: { name: string; size?: 'xs' | 'sm' | 'md' | 'lg' }) {
  const initials = name.split(' ').filter(Boolean).slice(0, 2).map(w => w[0]).join('').toUpperCase()
  const sz = { xs: 'w-6 h-6 text-[9px]', sm: 'w-8 h-8 text-[11px]', md: 'w-10 h-10 text-xs', lg: 'w-14 h-14 text-sm' }[size]
  return (
    <div className={`${sz} rounded-full bg-slate-100 border border-slate-200 flex items-center justify-center font-semibold text-slate-700 flex-shrink-0`}>
      {initials}
    </div>
  )
}

export function GoldDivider() {
  return <div className="h-px bg-[#E5E7EB]" />
}

export function SectionTitle({ children }: { children: ReactNode }) {
  return <h3 className="text-[10px] font-mono text-[#6B7280] uppercase tracking-widest mb-3">{children}</h3>
}

// ─── Deadline display ──────────────────────────────────────────────────────────

export function DeadlineBadge({ prazo }: { prazo: string }) {
  const days = Math.ceil((new Date(prazo).getTime() - Date.now()) / 86400000)
  const isLate = days < 0
  const isUrgent = days >= 0 && days <= 2
  const isSoon = days > 2 && days <= 5
  const color = isLate ? 'text-red-800 bg-red-50' : isUrgent ? 'text-orange-800 bg-orange-50' : isSoon ? 'text-amber-800 bg-amber-50' : 'text-slate-700 bg-slate-100'
  const label = isLate ? `${Math.abs(days)}d atraso` : `${days}d`
  const dateStr = new Date(prazo).toLocaleDateString('pt-PT', { day: '2-digit', month: 'short' })
  return (
    <span className={`inline-flex flex-col items-center px-2.5 py-1 text-[10px] font-mono rounded-md ${color}`}>
      <span className="font-semibold">{label}</span>
      <span className="text-[9px] opacity-70">{dateStr}</span>
    </span>
  )
}

// ─── Button ────────────────────────────────────────────────────────────────────

type BtnVariant = 'primary' | 'secondary' | 'ghost' | 'danger'
interface BtnProps { children: ReactNode; variant?: BtnVariant; size?: 'sm' | 'md'; onClick?: () => void; disabled?: boolean; type?: 'button' | 'submit' }

export function Btn({ children, variant = 'secondary', size = 'md', onClick, disabled, type = 'button' }: BtnProps) {
  const base = 'inline-flex items-center gap-1.5 font-medium rounded-sm transition-all duration-150 focus:outline-none focus-visible:ring-1 focus-visible:ring-[#C9A227] disabled:opacity-40 disabled:cursor-not-allowed whitespace-nowrap'
  const sz = size === 'sm' ? 'px-3 py-1.5 text-[11px]' : 'px-4 py-2 text-[12px]'
  const v = {
    primary:   'bg-[#C9A227] text-[#1F2937] hover:bg-[#D4AF37]',
    secondary: 'bg-white border border-[#E5E7EB] text-[#1F2937] hover:border-slate-300 hover:bg-slate-50',
    ghost:     'text-[#475569] hover:text-[#1F2937] hover:bg-slate-100',
    danger:    'bg-red-500/10 border border-red-500/30 text-red-700 hover:bg-red-500/20',
  }[variant]
  return <button type={type} onClick={onClick} disabled={disabled} className={`${base} ${sz} ${v}`}>{children}</button>
}

// ─── Input / Textarea ──────────────────────────────────────────────────────────

interface InputProps { label?: string; value: string; onChange: (v: string) => void; placeholder?: string; type?: string; required?: boolean }
export function Input({ label, value, onChange, placeholder, type = 'text', required }: InputProps) {
  return (
    <div className="space-y-1">
      {label && <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">{label}{required && <span className="text-red-600 ml-1">*</span>}</label>}
      <input type={type} value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} required={required}
        className="w-full px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none transition-colors" />
    </div>
  )
}

interface TextareaProps { label?: string; value: string; onChange: (v: string) => void; placeholder?: string; rows?: number }
export function Textarea({ label, value, onChange, placeholder, rows = 3 }: TextareaProps) {
  return (
    <div className="space-y-1">
      {label && <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">{label}</label>}
      <textarea value={value} onChange={e => onChange(e.target.value)} placeholder={placeholder} rows={rows}
        className="w-full px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none resize-none transition-colors" />
    </div>
  )
}

interface SelectProps { label?: string; value: string; onChange: (v: string) => void; options: { value: string; label: string }[]; required?: boolean }
export function Select({ label, value, onChange, options, required }: SelectProps) {
  return (
    <div className="space-y-1">
      {label && <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">{label}{required && <span className="text-red-600 ml-1">*</span>}</label>}
      <select value={value} onChange={e => onChange(e.target.value)}
        className="w-full px-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] focus:border-[#C9A227]/50 focus:outline-none transition-colors appearance-none">
        <option value="">Selecionar...</option>
        {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
    </div>
  )
}

// ─── Modal ─────────────────────────────────────────────────────────────────────

interface ModalProps { title: string; subtitle?: string; onClose: () => void; children: ReactNode; width?: string }
export function Modal({ title, subtitle, onClose, children, width = 'max-w-lg' }: ModalProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />
      <div className={`relative w-full ${width} bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm shadow-2xl flex flex-col max-h-[90vh]`}>
        <div className="flex items-start justify-between px-6 py-5 border-b border-[#E5E7EB] flex-shrink-0">
          <div>
            <h2 className="text-[15px] font-serif text-[#1F2937]">{title}</h2>
            {subtitle && <p className="text-[11px] text-[#64748B] mt-0.5">{subtitle}</p>}
          </div>
          <button onClick={onClose} className="text-[#6B7280] hover:text-[#1F2937] transition-colors text-xl leading-none ml-4 mt-0.5">×</button>
        </div>
        <div className="overflow-y-auto flex-1">{children}</div>
      </div>
    </div>
  )
}

// ─── Table primitives ──────────────────────────────────────────────────────────

export function TableHeader({ cols }: { cols: string[] }) {
  return (
    <div className="flex items-center gap-3 px-5 py-2.5 border-b border-[#E5E7EB] bg-[#FFFFFF] sticky top-0 z-10">
      {cols.map((c, i) => (
        <span key={i} className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider flex-1 first:flex-none">{c}</span>
      ))}
    </div>
  )
}

// ─── Empty / Loading / Error states ───────────────────────────────────────────

export function EmptyState({ icon = '◫', title, description }: { icon?: string; title: string; description?: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center px-8">
      <span className="text-4xl text-[#E5E7EB] mb-4">{icon}</span>
      <h3 className="text-[14px] font-serif text-[#6B7280]">{title}</h3>
      {description && <p className="text-[12px] text-[#9CA3AF] mt-2 max-w-xs">{description}</p>}
    </div>
  )
}

export function LoadingState() {
  return (
    <div className="flex items-center justify-center py-20">
      <div className="flex items-center gap-2 text-[#64748B]">
        <span className="text-slate-500 animate-pulse text-lg">◷</span>
        <span className="text-[12px] font-mono">A carregar...</span>
      </div>
    </div>
  )
}

// ─── Toggle ────────────────────────────────────────────────────────────────────

export function Toggle({ checked, onChange, label }: { checked: boolean; onChange: (v: boolean) => void; label?: string }) {
  return (
    <label className="flex items-center gap-2.5 cursor-pointer">
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        onClick={() => onChange(!checked)}
        className={`relative w-9 h-5 rounded-full transition-colors duration-200 focus:outline-none ${checked ? 'bg-[#C9A227]' : 'bg-[#E5E7EB]'}`}
      >
        <span className={`absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white transition-transform duration-200 ${checked ? 'translate-x-4' : 'translate-x-0'}`} />
      </button>
      {label && <span className="text-[12px] text-[#475569]">{label}</span>}
    </label>
  )
}

// ─── Search Input ─────────────────────────────────────────────────────────────

export function SearchInput({ value, onChange, placeholder = 'Pesquisar...' }: { value: string; onChange: (v: string) => void; placeholder?: string }) {
  return (
    <div className="relative">
      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280] text-sm">⌕</span>
      <input
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full pl-8 pr-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[12px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none transition-colors"
      />
      {value && (
        <button onClick={() => onChange('')} className="absolute right-2 top-1/2 -translate-y-1/2 text-[#6B7280] hover:text-[#1F2937] text-sm transition-colors">×</button>
      )}
    </div>
  )
}

// ─── Tabs ──────────────────────────────────────────────────────────────────────

interface Tab { id: string; label: string; count?: number }
interface TabsProps { tabs: Tab[]; active: string; onChange: (id: string) => void }
export function Tabs({ tabs, active, onChange }: TabsProps) {
  return (
    <div className="flex items-center border-b border-[#E5E7EB] overflow-x-auto">
      {tabs.map(t => (
        <button
          key={t.id}
          onClick={() => onChange(t.id)}
          className={`flex items-center gap-1.5 px-4 py-3 text-[12px] font-medium whitespace-nowrap border-b-2 transition-colors ${
            active === t.id ? 'border-[#C9A227] text-[#C9A227]' : 'border-transparent text-[#64748B] hover:text-[#1F2937]'
          }`}
        >
          {t.label}
          {t.count !== undefined && (
            <span className={`text-[10px] font-mono px-1.5 py-0.5 rounded-sm ${active === t.id ? 'bg-[#C9A227]/20 text-[#C9A227]' : 'bg-slate-100 text-[#6B7280]'}`}>{t.count}</span>
          )}
        </button>
      ))}
    </div>
  )
}

// ─── Confirm Dialog ────────────────────────────────────────────────────────────

interface ConfirmProps { title: string; message: string; confirmLabel?: string; onConfirm: () => void; onCancel: () => void; danger?: boolean }
export function ConfirmDialog({ title, message, confirmLabel = 'Confirmar', onConfirm, onCancel, danger }: ConfirmProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onCancel} />
      <div className="relative w-full max-w-sm bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm p-6 shadow-2xl">
        <h3 className="text-[14px] font-serif text-[#1F2937] mb-2">{title}</h3>
        <p className="text-[12px] text-[#475569] mb-6">{message}</p>
        <div className="flex items-center justify-end gap-2">
          <Btn variant="ghost" onClick={onCancel}>Cancelar</Btn>
          <Btn variant={danger ? 'danger' : 'primary'} onClick={onConfirm}>{confirmLabel}</Btn>
        </div>
      </div>
    </div>
  )
}

// ─── Field Display ─────────────────────────────────────────────────────────────

export function Field({ label, value, mono }: { label: string; value: ReactNode; mono?: boolean }) {
  return (
    <div>
      <p className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider mb-1">{label}</p>
      <p className={`text-[13px] text-[#1F2937] ${mono ? 'font-mono' : ''}`}>{value || <span className="text-[#9CA3AF]">—</span>}</p>
    </div>
  )
}

// ─── Toast ─────────────────────────────────────────────────────────────────────

export function Toast({ message, type = 'success', onClose }: { message: string; type?: 'success' | 'error' | 'warning'; onClose: () => void }) {
  const color = type === 'success' ? 'border-emerald-500/40 text-emerald-700' : type === 'error' ? 'border-red-500/40 text-red-700' : 'border-amber-500/40 text-amber-700'
  const icon = type === 'success' ? '✓' : type === 'error' ? '✕' : '!'
  return (
    <div className={`fixed bottom-5 right-5 z-[100] flex items-center gap-3 px-4 py-3 bg-[#F9FAFB] border ${color} rounded-sm shadow-xl`}>
      <span className={`text-sm ${color}`}>{icon}</span>
      <span className="text-[12px] text-[#1F2937]">{message}</span>
      <button onClick={onClose} className="text-[#6B7280] hover:text-[#1F2937] ml-2">×</button>
    </div>
  )
}

// ─── Page header ───────────────────────────────────────────────────────────────

export function PageHeader({ title, subtitle, actions }: { title: string; subtitle?: string; actions?: ReactNode }) {
  return (
    <div className="flex items-center justify-between px-7 py-5 border-b border-[#E5E7EB] flex-shrink-0">
      <div>
        <h1 className="text-[20px] font-serif text-[#1F2937]">{title}</h1>
        {subtitle && <p className="text-[12px] text-[#64748B] mt-0.5">{subtitle}</p>}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  )
}

// ─── Pagination ────────────────────────────────────────────────────────────────

interface PaginationProps { page: number; total: number; perPage: number; onChange: (p: number) => void }
export function Pagination({ page, total, perPage, onChange }: PaginationProps) {
  const pages = Math.ceil(total / perPage)
  if (pages <= 1) return null
  const start = (page - 1) * perPage + 1
  const end = Math.min(page * perPage, total)
  return (
    <div className="flex items-center justify-between px-5 py-3 border-t border-[#E5E7EB]">
      <span className="text-[11px] text-[#64748B] font-mono">{start}–{end} de {total}</span>
      <div className="flex items-center gap-1">
        <button onClick={() => onChange(page - 1)} disabled={page === 1} className="px-2 py-1 text-[11px] text-[#64748B] hover:text-[#1F2937] disabled:opacity-30 disabled:cursor-not-allowed">‹</button>
        {Array.from({ length: Math.min(pages, 7) }, (_, i) => i + 1).map(p => (
          <button key={p} onClick={() => onChange(p)} className={`w-7 h-7 text-[11px] font-mono rounded-sm ${p === page ? 'bg-[#C9A227]/15 text-[#C9A227] border border-[#C9A227]/30' : 'text-[#64748B] hover:text-[#1F2937]'}`}>{p}</button>
        ))}
        <button onClick={() => onChange(page + 1)} disabled={page === pages} className="px-2 py-1 text-[11px] text-[#64748B] hover:text-[#1F2937] disabled:opacity-30 disabled:cursor-not-allowed">›</button>
      </div>
    </div>
  )
}

// ─── useToast ─────────────────────────────────────────────────────────────────

export function useToast() {
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' | 'warning' } | null>(null)
  const show = (message: string, type: 'success' | 'error' | 'warning' = 'success') => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 3500)
  }
  const ToastEl = toast ? <Toast message={toast.message} type={toast.type} onClose={() => setToast(null)} /> : null
  return { show, ToastEl }
}

// ─── Skeleton loaders ──────────────────────────────────────────────────────────

export function Skeleton({ className = '' }: { className?: string }) {
  return <div className={`animate-pulse bg-[#F9FAFB] rounded-sm ${className}`} />
}

export function SkeletonRow() {
  return (
    <div className="flex items-center gap-4 px-5 py-3.5 border-b border-[#E5E7EB]">
      <Skeleton className="w-20 h-3" />
      <Skeleton className="w-32 h-3" />
      <Skeleton className="w-24 h-3" />
      <Skeleton className="w-20 h-3" />
      <Skeleton className="w-16 h-5 rounded-full" />
      <Skeleton className="w-24 h-3" />
      <Skeleton className="w-16 h-8" />
      <Skeleton className="w-12 h-5 rounded-full ml-auto" />
    </div>
  )
}

export function SkeletonCard() {
  return (
    <div className="p-4 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm space-y-3">
      <div className="flex items-center gap-2">
        <Skeleton className="w-8 h-8 rounded-full" />
        <div className="space-y-1.5 flex-1">
          <Skeleton className="w-3/4 h-3" />
          <Skeleton className="w-1/2 h-2.5" />
        </div>
      </div>
      <Skeleton className="w-full h-2.5" />
      <Skeleton className="w-2/3 h-2.5" />
    </div>
  )
}

export function SkeletonKPI() {
  return (
    <div className="p-5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm space-y-3">
      <Skeleton className="w-24 h-2.5" />
      <Skeleton className="w-16 h-8" />
      <Skeleton className="w-20 h-2.5" />
    </div>
  )
}

// ─── Error state ───────────────────────────────────────────────────────────────

export function ErrorState({ message = 'Ocorreu um erro ao carregar os dados.', onRetry }: { message?: string; onRetry?: () => void }) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center px-8">
      <span className="text-3xl text-red-700/40 mb-4">⊗</span>
      <h3 className="text-[13px] font-serif text-[#64748B]">Erro ao carregar</h3>
      <p className="text-[12px] text-[#9CA3AF] mt-1 max-w-xs">{message}</p>
      {onRetry && (
        <button onClick={onRetry} className="mt-4 text-[11px] text-[#C9A227] hover:text-[#D4AF37] transition-colors font-mono">
          ↺ Tentar novamente
        </button>
      )}
    </div>
  )
}

// ─── Warning banner ────────────────────────────────────────────────────────────

export function WarningBanner({ message, onDismiss }: { message: string; onDismiss?: () => void }) {
  return (
    <div className="flex items-center gap-3 px-5 py-3 bg-amber-400/8 border-b border-amber-400/20">
      <span className="text-amber-700 text-sm flex-shrink-0">⚠</span>
      <span className="text-[12px] text-amber-700 flex-1">{message}</span>
      {onDismiss && (
        <button onClick={onDismiss} className="text-amber-700/50 hover:text-amber-700 transition-colors text-sm">×</button>
      )}
    </div>
  )
}

// ─── Visibility badge ──────────────────────────────────────────────────────────

export function VisibilityBadge({ visibility, onChange }: { visibility: 'interna' | 'cliente'; onChange?: (v: 'interna' | 'cliente') => void }) {
  const isClient = visibility === 'cliente'
  return (
    <button
      onClick={onChange ? () => onChange(isClient ? 'interna' : 'cliente') : undefined}
      disabled={!onChange}
      title={onChange ? 'Clique para alterar visibilidade' : undefined}
      className={`inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-mono border rounded-sm transition-all ${
        isClient
          ? 'text-emerald-700 bg-emerald-400/10 border-emerald-400/25 hover:bg-emerald-400/20'
          : 'text-slate-500 bg-zinc-500/8 border-zinc-500/20 hover:bg-zinc-500/15'
      } ${!onChange ? 'cursor-default' : 'cursor-pointer'}`}>
      {isClient ? '👁 Visível ao cliente' : '🔒 Interno'}
    </button>
  )
}
