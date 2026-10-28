import { type ReactNode, useId, useState } from 'react'
import type {
  WorkStatus,
  StepStatus,
  ClientStatus,
  ColabStatus,
  WorkNature,
  UserRole,
} from '../data'
import { AppIcon } from './icons'

// ─── Status configs ────────────────────────────────────────────────────────────

export const WORK_STATUS: Record<
  WorkStatus,
  { label: string; color: string; dot: string }
> = {
  por_receber: {
    label: 'Em avaliação',
    color: 'text-[var(--gold-ink)] bg-[var(--gold-soft)]',
    dot: 'bg-[var(--gold-ink)]',
  },
  encaminhado: {
    label: 'Por iniciar',
    color: 'text-[var(--gold-ink)] bg-[var(--gold-soft)]',
    dot: 'bg-[var(--gold-ink)]',
  },
  em_producao: {
    label: 'Em processamento',
    color: 'text-[var(--badge-process-text)] bg-[var(--badge-process-bg)]',
    dot: 'bg-[var(--badge-process-text)]',
  },
  em_standby: {
    label: 'Em espera',
    color: 'text-[var(--badge-standby-text)] bg-[var(--badge-standby-bg)]',
    dot: 'bg-[var(--badge-standby-text)]',
  },
  aguarda_aprovacao: {
    label: 'Em prova',
    color: 'text-[var(--gold-ink)] bg-[var(--gold-soft)]',
    dot: 'bg-[var(--gold)]',
  },
  concluido: {
    label: 'Concluído',
    color: 'text-[var(--badge-success-text)] bg-[var(--badge-success-bg)]',
    dot: 'bg-[var(--badge-success-text)]',
  },
}

const CLINIC_ORDER_STATUS: Record<
  WorkStatus,
  { label: string; color: string; dot: string }
> = {
  por_receber: {
    label: 'Iniciar',
    color: 'text-[var(--gold-ink)] bg-[var(--gold-soft)]',
    dot: 'bg-[var(--gold-ink)]',
  },
  encaminhado: {
    label: 'Iniciar',
    color: 'text-[var(--gold-ink)] bg-[var(--gold-soft)]',
    dot: 'bg-[var(--gold-ink)]',
  },
  em_producao: {
    label: 'Processamento',
    color: 'text-[var(--badge-process-text)] bg-[var(--badge-process-bg)]',
    dot: 'bg-[var(--badge-process-text)]',
  },
  em_standby: {
    label: 'Processamento',
    color: 'text-[var(--badge-process-text)] bg-[var(--badge-process-bg)]',
    dot: 'bg-[var(--badge-process-text)]',
  },
  aguarda_aprovacao: {
    label: 'Processamento',
    color: 'text-[var(--badge-process-text)] bg-[var(--badge-process-bg)]',
    dot: 'bg-[var(--badge-process-text)]',
  },
  concluido: {
    label: 'Concluído',
    color: 'text-[var(--badge-success-text)] bg-[var(--badge-success-bg)]',
    dot: 'bg-[var(--badge-success-text)]',
  },
}

export const STEP_STATUS: Record<
  StepStatus,
  { label: string; color: string; ring: string }
> = {
  nao_iniciado: {
    label: 'Não iniciado',
    color: 'text-[var(--gold-ink)]',
    ring: 'border-[var(--gold)] bg-[var(--gold-soft)]',
  },
  em_execucao: {
    label: 'Em execução',
    color: 'text-[var(--badge-process-text)]',
    ring: 'border-[var(--badge-process-text)] bg-[var(--badge-process-bg)]',
  },
  concluida: {
    label: 'Concluída',
    color: 'text-[var(--badge-success-text)]',
    ring: 'border-[var(--badge-success-text)] bg-[var(--badge-success-bg)]',
  },
  standby: {
    label: 'Standby',
    color: 'text-[var(--badge-standby-text)]',
    ring: 'border-[var(--badge-standby-text)] bg-[var(--badge-standby-bg)]',
  },
  cancelada: {
    label: 'Cancelada',
    color: 'text-[var(--badge-standby-text)]',
    ring: 'border-[var(--badge-standby-text)] bg-[var(--badge-standby-bg)]',
  },
}

export const CLIENT_STATUS: Record<
  ClientStatus,
  { label: string; color: string; dot: string }
> = {
  ativo: {
    label: 'Ativo',
    color: 'text-[var(--badge-success-text)] bg-[var(--badge-success-bg)]',
    dot: 'bg-[var(--badge-success-text)]',
  },
  suspenso: {
    label: 'Suspenso',
    color: 'text-[var(--badge-standby-text)] bg-[var(--badge-standby-bg)]',
    dot: 'bg-[var(--badge-standby-text)]',
  },
  aguarda_validacao: {
    label: 'A aguardar validação',
    color: 'text-[var(--gold-ink)] bg-[var(--gold-soft)]',
    dot: 'bg-[var(--gold-ink)]',
  },
}

export const NATURE_CONFIG: Record<
  WorkNature,
  { label: string; color: string }
> = {
  fisico: { label: 'Físico', color: 'text-[var(--ink)] bg-[var(--soft)]' },
  digital: {
    label: 'Digital',
    color: 'text-[var(--badge-process-text)] bg-[var(--badge-process-bg)]',
  },
}

export const ROLE_CONFIG: Record<UserRole, { label: string; color: string }> = {
  admin: {
    label: 'Administrador',
    color: 'text-[var(--ink)] bg-[var(--soft)] border-[var(--line)]',
  },
  colaborador: {
    label: 'Colaborador',
    color: 'text-[var(--ink)] bg-[var(--soft)] border-[var(--line)]',
  },
  clinica: {
    label: 'Clínica',
    color: 'text-[var(--gold-ink)] bg-[var(--gold-soft)] border-[var(--gold)]',
  },
}

export const COLAB_STATUS: Record<ColabStatus, { label: string; dot: string }> =
  {
    disponivel: { label: 'Disponível', dot: 'bg-[var(--badge-success-text)]' },
    ocupado: { label: 'Ocupado', dot: 'bg-[var(--gold-ink)]' },
    ausente: { label: 'Ausente', dot: 'bg-[var(--muted)]' },
  }

// ─── Primitive components ──────────────────────────────────────────────────────

export function StatusBadge({
  status,
  audience = 'internal',
  stage,
}: {
  status: WorkStatus
  audience?: 'internal' | 'clinic'
  stage?: string
}) {
  const baseConfig =
    audience === 'clinic' ? CLINIC_ORDER_STATUS[status] : WORK_STATUS[status]
  const cfg =
    audience === 'internal' &&
    status === 'concluido' &&
    stage?.toLowerCase() === 'entregue'
      ? {
          label: 'Entregue',
          color:
            'text-[var(--badge-success-text)] bg-[var(--badge-success-bg)]',
          dot: 'bg-[var(--badge-success-text)]',
        }
      : baseConfig
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono font-medium rounded-md whitespace-nowrap ${cfg.color}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${cfg.dot}`} />
      {cfg.label}
    </span>
  )
}

export function NatureBadge({ natureza }: { natureza: WorkNature }) {
  const cfg = NATURE_CONFIG[natureza]
  return (
    <span
      className={`inline-flex items-center gap-1 px-2 py-1 text-[10px] font-mono font-medium rounded-md ${cfg.color}`}
    >
      <AppIcon
        name={natureza === 'fisico' ? 'package' : 'clipboard'}
        className="h-3.5 w-3.5"
      />
      {cfg.label}
    </span>
  )
}

export function RoleBadge({ role }: { role: UserRole }) {
  const cfg = ROLE_CONFIG[role]
  return (
    <span
      className={`inline-flex items-center px-2 py-0.5 text-[10px] font-mono border rounded-sm ${cfg.color}`}
    >
      {cfg.label}
    </span>
  )
}

export function ClientStatusBadge({ status }: { status: ClientStatus }) {
  const cfg = CLIENT_STATUS[status]
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 text-[11px] font-mono font-medium rounded-md ${cfg.color}`}
    >
      <span className={`w-1.5 h-1.5 rounded-full ${cfg.dot}`} />
      {cfg.label}
    </span>
  )
}

export function Avatar({
  name,
  size = 'sm',
}: {
  name: string
  size?: 'xs' | 'sm' | 'md' | 'lg'
}) {
  const initials = name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0])
    .join('')
    .toUpperCase()
  const sz = {
    xs: 'w-6 h-6 text-[9px]',
    sm: 'w-8 h-8 text-[11px]',
    md: 'w-10 h-10 text-xs',
    lg: 'w-14 h-14 text-sm',
  }[size]
  return (
    <div
      className={`${sz} rounded-full bg-[var(--soft)] border border-[var(--line)] flex items-center justify-center font-semibold text-[var(--ink)] flex-shrink-0`}
    >
      {initials}
    </div>
  )
}

export function GoldDivider() {
  return <div className="h-px bg-[var(--line)]" />
}

export function SectionTitle({ children }: { children: ReactNode }) {
  return (
    <h3 className="text-[10px] font-mono font-bold text-[var(--muted)] uppercase tracking-widest mb-3">
      {children}
    </h3>
  )
}

// ─── Deadline display ──────────────────────────────────────────────────────────

export function DeadlineBadge({
  prazo,
  status,
}: {
  prazo: string
  status?: WorkStatus
}) {
  const days = Math.ceil((new Date(prazo).getTime() - Date.now()) / 86400000)
  const closed = status === 'concluido'
  const isLate = !closed && days < 0
  const isUrgent = !closed && days >= 0 && days <= 2
  const isSoon = !closed && days > 2 && days <= 5
  const color =
    isLate || isUrgent
      ? 'text-[var(--badge-standby-text)] bg-[var(--badge-standby-bg)]'
      : isSoon
        ? 'text-[var(--gold-ink)] bg-[var(--gold-soft)]'
        : 'text-[var(--ink)] bg-[var(--soft)]'
  const label = closed
    ? 'Concluído'
    : isLate
      ? `${Math.abs(days)}d atraso`
      : `${days}d`
  const dateStr = new Date(prazo).toLocaleDateString('pt-PT', {
    day: '2-digit',
    month: 'short',
  })
  return (
    <span
      className={`inline-flex flex-col items-center px-2.5 py-1 text-[10px] font-mono rounded-md ${color}`}
    >
      <span className="font-semibold">{label}</span>
      <span className="text-[9px]">{dateStr}</span>
    </span>
  )
}

// ─── Button ────────────────────────────────────────────────────────────────────

type BtnVariant = 'primary' | 'secondary' | 'ghost' | 'danger'
interface BtnProps {
  children: ReactNode
  variant?: BtnVariant
  size?: 'sm' | 'md'
  onClick?: () => void
  disabled?: boolean
  type?: 'button' | 'submit'
}

export function Btn({
  children,
  variant = 'secondary',
  size = 'md',
  onClick,
  disabled,
  type = 'button',
}: BtnProps) {
  const base =
    'inline-flex min-h-9 items-center gap-1.5 rounded-[5px] font-semibold transition-all duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--gold-ink)] focus-visible:ring-offset-2 disabled:opacity-40 disabled:cursor-not-allowed whitespace-nowrap'
  const sz = size === 'sm' ? 'px-3 py-1.5 text-[11px]' : 'px-4 py-2 text-[12px]'
  const v = {
    primary: 'bg-[var(--gold)] text-[#181B20] hover:opacity-90',
    secondary:
      'bg-transparent border border-[var(--line)] text-[var(--ink)] hover:bg-[var(--soft)]',
    ghost: 'bg-transparent text-[var(--ink)] hover:bg-[var(--soft)]',
    danger:
      'bg-[var(--badge-standby-bg)] border border-[var(--badge-standby-text)] text-[var(--badge-standby-text)] hover:brightness-95',
  }[variant]
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`${base} ${sz} ${v}`}
    >
      {children}
    </button>
  )
}

// ─── Input / Textarea ──────────────────────────────────────────────────────────

interface InputProps {
  label?: string
  value: string
  onChange: (v: string) => void
  placeholder?: string
  type?: string
  required?: boolean
}
export function Input({
  label,
  value,
  onChange,
  placeholder,
  type = 'text',
  required,
}: InputProps) {
  return (
    <div className="space-y-1">
      {label && (
        <label className="text-[10px] font-mono text-[var(--muted)] uppercase tracking-wider">
          {label}
          {required && (
            <span className="text-[var(--badge-standby-text)] ml-1">*</span>
          )}
        </label>
      )}
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        required={required}
        className="w-full min-h-11 px-3 py-2 bg-[var(--surface)] border border-[var(--input-line)] rounded-[5px] text-[13px] text-[var(--ink)] placeholder:text-[var(--muted)] focus:border-[var(--gold-ink)] focus:outline-none focus:ring-2 focus:ring-[var(--gold-ink)] focus:ring-offset-2 transition-colors"
      />
    </div>
  )
}

interface TextareaProps {
  label?: string
  value: string
  onChange: (v: string) => void
  placeholder?: string
  rows?: number
}
export function Textarea({
  label,
  value,
  onChange,
  placeholder,
  rows = 3,
}: TextareaProps) {
  const id = useId()
  return (
    <div className="space-y-1">
      {label && (
        <label
          htmlFor={id}
          className="text-[10px] font-mono text-[var(--muted)] uppercase tracking-wider"
        >
          {label}
        </label>
      )}
      <textarea
        id={id}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        rows={rows}
        className="w-full px-3 py-2 bg-[var(--surface)] border border-[var(--input-line)] rounded-[5px] text-[13px] text-[var(--ink)] placeholder:text-[var(--muted)] focus:border-[var(--gold-ink)] focus:outline-none focus:ring-2 focus:ring-[var(--gold-ink)] focus:ring-offset-2 resize-none transition-colors"
      />
    </div>
  )
}

interface SelectProps {
  label?: string
  value: string
  onChange: (v: string) => void
  options: ReadonlyArray<{ value: string; label: string }>
  required?: boolean
}
export function Select({
  label,
  value,
  onChange,
  options,
  required,
}: SelectProps) {
  const id = useId()
  return (
    <div className="space-y-1">
      {label && (
        <label
          htmlFor={id}
          className="text-[10px] font-mono text-[var(--muted)] uppercase tracking-wider"
        >
          {label}
          {required && (
            <span className="text-[var(--badge-standby-text)] ml-1">*</span>
          )}
        </label>
      )}
      <select
        id={id}
        required={required}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className="w-full min-h-11 px-3 py-2 bg-[var(--surface)] border border-[var(--input-line)] rounded-[5px] text-[13px] text-[var(--ink)] focus:border-[var(--gold-ink)] focus:outline-none focus:ring-2 focus:ring-[var(--gold-ink)] focus:ring-offset-2 transition-colors appearance-none"
      >
        <option value="">Selecionar...</option>
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </div>
  )
}

// ─── Modal ─────────────────────────────────────────────────────────────────────

interface ModalProps {
  title: string
  subtitle?: string
  onClose: () => void
  children: ReactNode
  width?: string
}
export function Modal({
  title,
  subtitle,
  onClose,
  children,
  width = 'max-w-lg',
}: ModalProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-black/70 backdrop-blur-sm"
        onClick={onClose}
      />
      <div
        className={`relative w-full ${width} bg-[var(--surface)] text-[var(--ink)] border border-[var(--line)] rounded-2xl shadow-2xl flex flex-col max-h-[90vh]`}
      >
        <div className="flex items-start justify-between px-6 py-5 border-b border-[var(--line)] flex-shrink-0">
          <div>
            <h2 className="text-[15px] font-serif text-[var(--ink)]">
              {title}
            </h2>
            {subtitle && (
              <p className="text-[11px] text-[var(--muted)] mt-0.5">
                {subtitle}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="text-[var(--muted)] hover:text-[var(--ink)] transition-colors text-xl leading-none ml-4 mt-0.5"
          >
            ×
          </button>
        </div>
        <div className="overflow-y-auto flex-1">{children}</div>
      </div>
    </div>
  )
}

// ─── Table primitives ──────────────────────────────────────────────────────────

export function TableHeader({ cols }: { cols: string[] }) {
  return (
    <div className="flex items-center gap-3 px-5 py-2.5 border-b border-[var(--line)] bg-[var(--surface)] text-[var(--ink)] sticky top-0 z-10">
      {cols.map((c, i) => (
        <span
          key={i}
          className="text-[10px] font-mono text-[var(--muted)] uppercase tracking-wider flex-1 first:flex-none"
        >
          {c}
        </span>
      ))}
    </div>
  )
}

// ─── Empty / Loading / Error states ───────────────────────────────────────────

export function EmptyState({
  icon = '◫',
  title,
  description,
}: {
  icon?: string
  title: string
  description?: string
}) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center px-8">
      <span className="text-4xl text-[var(--muted)] mb-4">{icon}</span>
      <h3 className="text-[14px] font-serif text-[var(--ink)]">{title}</h3>
      {description && (
        <p className="text-[12px] text-[var(--muted)] mt-2 max-w-xs">
          {description}
        </p>
      )}
    </div>
  )
}

export function LoadingState() {
  return (
    <div className="flex items-center justify-center py-20">
      <div className="flex items-center gap-2 text-[var(--muted)]">
        <span className="text-[var(--muted)] animate-pulse text-lg">◷</span>
        <span className="text-[12px] font-mono">A carregar...</span>
      </div>
    </div>
  )
}

// ─── Toggle ────────────────────────────────────────────────────────────────────

export function Toggle({
  checked,
  onChange,
  label,
}: {
  checked: boolean
  onChange: (v: boolean) => void
  label?: string
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label || 'Ativo'}
      onClick={() => onChange(!checked)}
      className="inline-flex min-h-11 min-w-11 items-center justify-center gap-2.5 rounded-md focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--gold-ink)]"
    >
      <span
        aria-hidden="true"
        style={{
          width: 36,
          height: 20,
          padding: 2,
          display: 'inline-flex',
          alignItems: 'center',
          flexShrink: 0,
          borderRadius: 6,
          background: checked ? 'var(--gold)' : 'var(--line)',
        }}
      >
        <span
          style={{
            width: 14,
            height: 14,
            borderRadius: 4,
            background: '#FFFFFF',
            boxShadow: '0 1px 2px #0002',
            transform: checked ? 'translateX(16px)' : 'translateX(0)',
            transition: 'transform 150ms ease',
          }}
        />
      </span>
      {label && <span className="text-[12px] text-[var(--ink)]">{label}</span>}
    </button>
  )
}

// ─── Search Input ─────────────────────────────────────────────────────────────

export function SearchInput({
  value,
  onChange,
  placeholder = 'Pesquisar...',
}: {
  value: string
  onChange: (v: string) => void
  placeholder?: string
}) {
  return (
    <div className="relative">
      <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[var(--muted)] text-sm">
        ⌕
      </span>
      <input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full pl-8 pr-3 py-2 bg-[var(--surface)] border border-[var(--input-line)] rounded-[5px] text-[12px] text-[var(--ink)] placeholder:text-[var(--muted)] focus:border-[var(--gold-ink)] focus:outline-none focus:ring-2 focus:ring-[var(--gold-ink)] focus:ring-offset-2 transition-colors"
      />
      {value && (
        <button
          onClick={() => onChange('')}
          className="absolute right-2 top-1/2 -translate-y-1/2 text-[var(--muted)] hover:text-[var(--ink)] text-sm transition-colors"
        >
          ×
        </button>
      )}
    </div>
  )
}

// ─── Tabs ──────────────────────────────────────────────────────────────────────

interface Tab {
  id: string
  label: string
  count?: number
}
interface TabsProps {
  tabs: Tab[]
  active: string
  onChange: (id: string) => void
}
export function Tabs({ tabs, active, onChange }: TabsProps) {
  return (
    <div className="flex items-center border-b border-[var(--line)] overflow-x-auto">
      {tabs.map((t) => (
        <button
          key={t.id}
          onClick={() => onChange(t.id)}
          className={`flex items-center gap-1.5 px-4 py-3 text-[12px] font-medium whitespace-nowrap border-b-2 transition-colors ${
            active === t.id
              ? 'border-[var(--gold-ink)] text-[var(--gold-ink)]'
              : 'border-transparent text-[var(--muted)] hover:text-[var(--ink)]'
          }`}
        >
          {t.label}
          {t.count !== undefined && (
            <span
              className={`text-[10px] font-mono px-1.5 py-0.5 rounded-sm ${
                active === t.id
                  ? 'bg-[var(--gold-soft)] text-[var(--gold-ink)]'
                  : 'bg-[var(--soft)] text-[var(--muted)]'
              }`}
            >
              {t.count}
            </span>
          )}
        </button>
      ))}
    </div>
  )
}

// ─── Confirm Dialog ────────────────────────────────────────────────────────────

interface ConfirmProps {
  title: string
  message: string
  confirmLabel?: string
  onConfirm: () => void
  onCancel: () => void
  danger?: boolean
}
export function ConfirmDialog({
  title,
  message,
  confirmLabel = 'Confirmar',
  onConfirm,
  onCancel,
  danger,
}: ConfirmProps) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-black/70 backdrop-blur-sm"
        onClick={onCancel}
      />
      <div className="relative w-full max-w-sm bg-[var(--surface)] text-[var(--ink)] border border-[var(--line)] rounded-[5px] p-6 shadow-2xl">
        <h3 className="text-[14px] font-serif text-[var(--ink)] mb-2">
          {title}
        </h3>
        <p className="text-[12px] text-[var(--muted)] mb-6">{message}</p>
        <div className="flex items-center justify-end gap-2">
          <Btn variant="ghost" onClick={onCancel}>
            Cancelar
          </Btn>
          <Btn variant={danger ? 'danger' : 'primary'} onClick={onConfirm}>
            {confirmLabel}
          </Btn>
        </div>
      </div>
    </div>
  )
}

// ─── Field Display ─────────────────────────────────────────────────────────────

export function Field({
  label,
  value,
  mono,
}: {
  label: string
  value: ReactNode
  mono?: boolean
}) {
  return (
    <div>
      <p className="text-[10px] font-mono text-[var(--muted)] uppercase tracking-wider mb-1">
        {label}
      </p>
      <p className={`text-[13px] text-[var(--ink)] ${mono ? 'font-mono' : ''}`}>
        {value || <span className="text-[var(--muted)]">—</span>}
      </p>
    </div>
  )
}

// ─── Toast ─────────────────────────────────────────────────────────────────────

export function Toast({
  message,
  type = 'success',
  onClose,
}: {
  message: string
  type?: 'success' | 'error' | 'warning'
  onClose: () => void
}) {
  const color =
    type === 'success'
      ? 'border-[var(--badge-success-text)] text-[var(--badge-success-text)] bg-[var(--badge-success-bg)]'
      : type === 'error'
        ? 'border-[var(--badge-standby-text)] text-[var(--badge-standby-text)] bg-[var(--badge-standby-bg)]'
        : 'border-[var(--gold)] text-[var(--gold-ink)] bg-[var(--gold-soft)]'
  const icon = type === 'success' ? '✓' : type === 'error' ? '✕' : '!'
  return (
    <div
      className={`fixed bottom-5 right-5 z-[100] flex items-center gap-3 px-4 py-3 border ${color} rounded-[5px] shadow-xl`}
    >
      <span className="text-sm">{icon}</span>
      <span className="text-[12px] text-current">{message}</span>
      <button onClick={onClose} className="text-current hover:opacity-75 ml-2">
        ×
      </button>
    </div>
  )
}

// ─── Page header ───────────────────────────────────────────────────────────────

export function PageHeader({
  title,
  subtitle,
  actions,
}: {
  title: string
  subtitle?: string
  actions?: ReactNode
}) {
  return (
    <div className="flex items-center justify-between px-7 py-5 border-b border-[var(--line)] flex-shrink-0">
      <div>
        <h1 className="text-[20px] font-serif text-[var(--ink)]">{title}</h1>
        {subtitle && (
          <p className="text-[12px] text-[var(--muted)] mt-0.5">{subtitle}</p>
        )}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  )
}

// ─── Pagination ────────────────────────────────────────────────────────────────

interface PaginationProps {
  page: number
  total: number
  perPage: number
  onChange: (p: number) => void
}
export function Pagination({
  page,
  total,
  perPage,
  onChange,
}: PaginationProps) {
  const pages = Math.ceil(total / perPage)
  if (pages <= 1) return null
  const start = (page - 1) * perPage + 1
  const end = Math.min(page * perPage, total)
  return (
    <div className="flex items-center justify-between px-5 py-3 border-t border-[var(--line)]">
      <span className="text-[11px] text-[var(--muted)] font-mono">
        {start}–{end} de {total}
      </span>
      <div className="flex items-center gap-1">
        <button
          onClick={() => onChange(page - 1)}
          disabled={page === 1}
          className="px-2 py-1 text-[11px] text-[var(--muted)] hover:text-[var(--ink)] disabled:opacity-30 disabled:cursor-not-allowed"
        >
          ‹
        </button>
        {Array.from({ length: Math.min(pages, 7) }, (_, i) => i + 1).map(
          (p) => (
            <button
              key={p}
              onClick={() => onChange(p)}
              className={`w-7 h-7 text-[11px] font-mono rounded-[5px] ${
                p === page
                  ? 'bg-[var(--gold-soft)] text-[var(--gold-ink)] border border-[var(--gold)]'
                  : 'text-[var(--muted)] hover:text-[var(--ink)]'
              }`}
            >
              {p}
            </button>
          ),
        )}
        <button
          onClick={() => onChange(page + 1)}
          disabled={page === pages}
          className="px-2 py-1 text-[11px] text-[var(--muted)] hover:text-[var(--ink)] disabled:opacity-30 disabled:cursor-not-allowed"
        >
          ›
        </button>
      </div>
    </div>
  )
}

// ─── useToast ─────────────────────────────────────────────────────────────────

export function useToast() {
  const [toast, setToast] = useState<{
    message: string
    type: 'success' | 'error' | 'warning'
  } | null>(null)
  const show = (
    message: string,
    type: 'success' | 'error' | 'warning' = 'success',
  ) => {
    setToast({ message, type })
    setTimeout(() => setToast(null), 3500)
  }
  const ToastEl = toast ? (
    <Toast
      message={toast.message}
      type={toast.type}
      onClose={() => setToast(null)}
    />
  ) : null
  return { show, ToastEl }
}

// ─── Skeleton loaders ──────────────────────────────────────────────────────────

export function Skeleton({ className = '' }: { className?: string }) {
  return (
    <div className={`animate-pulse bg-[var(--soft)] rounded-sm ${className}`} />
  )
}

export function SkeletonRow() {
  return (
    <div className="flex items-center gap-4 px-5 py-3.5 border-b border-[var(--line)]">
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
    <div className="p-4 bg-[var(--surface)] text-[var(--ink)] border border-[var(--line)] rounded-[5px] space-y-3">
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
    <div className="p-5 bg-[var(--surface)] text-[var(--ink)] border border-[var(--line)] rounded-[5px] space-y-3">
      <Skeleton className="w-24 h-2.5" />
      <Skeleton className="w-16 h-8" />
      <Skeleton className="w-20 h-2.5" />
    </div>
  )
}

// ─── Error state ───────────────────────────────────────────────────────────────

export function ErrorState({
  message = 'Ocorreu um erro ao carregar os dados.',
  onRetry,
}: {
  message?: string
  onRetry?: () => void
}) {
  return (
    <div className="flex flex-col items-center justify-center py-20 text-center px-8">
      <span className="text-3xl text-[var(--badge-standby-text)] mb-4">⊗</span>
      <h3 className="text-[13px] font-serif text-[var(--ink)]">
        Erro ao carregar
      </h3>
      <p className="text-[12px] text-[var(--muted)] mt-1 max-w-xs">{message}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="mt-4 text-[11px] text-[var(--gold-ink)] hover:opacity-80 transition-opacity font-mono"
        >
          ↺ Tentar novamente
        </button>
      )}
    </div>
  )
}

// ─── Warning banner ────────────────────────────────────────────────────────────

export function WarningBanner({
  message,
  onDismiss,
}: {
  message: string
  onDismiss?: () => void
}) {
  return (
    <div className="flex items-center gap-3 px-5 py-3 bg-[var(--badge-standby-bg)] border-b border-[var(--badge-standby-text)]">
      <span className="text-[var(--badge-standby-text)] text-sm flex-shrink-0">
        ⚠
      </span>
      <span className="text-[12px] text-[var(--badge-standby-text)] flex-1">
        {message}
      </span>
      {onDismiss && (
        <button
          onClick={onDismiss}
          className="text-[var(--badge-standby-text)] hover:opacity-75 transition-opacity text-sm"
        >
          ×
        </button>
      )}
    </div>
  )
}

// ─── Visibility badge ──────────────────────────────────────────────────────────

export function VisibilityBadge({
  visibility,
  onChange,
}: {
  visibility: 'interna' | 'cliente'
  onChange?: (v: 'interna' | 'cliente') => void
}) {
  const isClient = visibility === 'cliente'
  return (
    <button
      onClick={
        onChange ? () => onChange(isClient ? 'interna' : 'cliente') : undefined
      }
      disabled={!onChange}
      title={onChange ? 'Clique para alterar visibilidade' : undefined}
      className={`inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-mono border rounded-sm transition-all ${
        isClient
          ? 'text-[var(--badge-success-text)] bg-[var(--badge-success-bg)] border-[var(--badge-success-text)] hover:brightness-95'
          : 'text-[var(--ink)] bg-[var(--soft)] border-[var(--line)] hover:brightness-95'
      } ${!onChange ? 'cursor-default' : 'cursor-pointer'}`}
    >
      <AppIcon name={isClient ? 'eye' : 'lock'} className="h-3.5 w-3.5" />
      {isClient ? 'Visível ao cliente' : 'Interno'}
    </button>
  )
}
