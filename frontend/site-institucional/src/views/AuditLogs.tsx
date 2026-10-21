import { useMemo, useState } from 'react'
import type { UserRole } from '../data'
import { RoleBadge, SearchInput } from '../components/ui'

type AuditEntry = {
  id: string
  timestamp: string
  author: string
  role: UserRole
  action: 'Criação' | 'Atualização' | 'Estado' | 'Acesso' | 'Reabertura'
  target: string
  summary: string
}

const AUDIT_ENTRIES: AuditEntry[] = [
  { id: 'a1', timestamp: '2025-01-16T14:32:18', author: 'Catarina Domingos', role: 'admin', action: 'Reabertura', target: 'LCD-2024-0844', summary: 'Trabalho reaberto; etapas Acabamento e Controlo de Qualidade repostas.' },
  { id: 'a2', timestamp: '2025-01-16T13:55:04', author: 'Ana Martins', role: 'colaborador', action: 'Estado', target: 'LCD-2024-0847', summary: 'Etapa Enceramento marcada como concluída.' },
  { id: 'a3', timestamp: '2025-01-16T12:10:42', author: 'Marta Oliveira', role: 'rececionista', action: 'Atualização', target: 'CLI-c1', summary: 'Contacto principal da Clínica Dental Horizonte atualizado.' },
  { id: 'a4', timestamp: '2025-01-16T11:48:11', author: 'Catarina Domingos', role: 'admin', action: 'Criação', target: 'PROC-p5', summary: 'Novo processo de produção criado.' },
  { id: 'a5', timestamp: '2025-01-16T09:15:36', author: 'Jorge Vieira', role: 'colaborador', action: 'Estado', target: 'LCD-2024-0850', summary: 'Trabalho colocado em standby com justificação.' },
  { id: 'a6', timestamp: '2025-01-15T17:42:09', author: 'Catarina Domingos', role: 'admin', action: 'Acesso', target: 'USR-col2', summary: 'Permissões do colaborador Pedro Santos atualizadas.' },
]

export default function AuditLogs() {
  const [search, setSearch] = useState('')
  const [author, setAuthor] = useState('')
  const [action, setAction] = useState('')
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')

  const filtered = useMemo(() => AUDIT_ENTRIES.filter(entry => {
    const query = search.toLowerCase()
    const matchesSearch = !query
      || entry.author.toLowerCase().includes(query)
      || entry.target.toLowerCase().includes(query)
      || entry.summary.toLowerCase().includes(query)
    const date = entry.timestamp.slice(0, 10)
    return matchesSearch
      && (!author || entry.author === author)
      && (!action || entry.action === action)
      && (!from || date >= from)
      && (!to || date <= to)
  }), [search, author, action, from, to])

  return (
    <div className="flex-1 flex flex-col overflow-hidden">
      <div className="flex-shrink-0 border-b border-[#E5E7EB] bg-[#FFFFFF] px-7 py-5">
        <div className="flex items-end gap-3 flex-wrap">
          <div className="w-72">
            <SearchInput value={search} onChange={setSearch} placeholder="Pesquisar autor, referência ou alteração..." />
          </div>
          <AuditSelect label="Autor" value={author} onChange={setAuthor}>
            <option value="">Todos</option>
            {[...new Set(AUDIT_ENTRIES.map(entry => entry.author))].map(name => <option key={name}>{name}</option>)}
          </AuditSelect>
          <AuditSelect label="Ação" value={action} onChange={setAction}>
            <option value="">Todas</option>
            {['Criação', 'Atualização', 'Estado', 'Acesso', 'Reabertura'].map(value => <option key={value}>{value}</option>)}
          </AuditSelect>
          <AuditDate label="De" value={from} onChange={setFrom} />
          <AuditDate label="Até" value={to} onChange={setTo} />
          <button
            onClick={() => { setSearch(''); setAuthor(''); setAction(''); setFrom(''); setTo('') }}
            className="px-3 py-2 text-[11px] text-[#64748B] hover:text-[#1F2937]"
          >
            Limpar filtros
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-auto bg-[#FFFFFF]">
        <div className="min-w-[1050px]">
          <div className="grid grid-cols-[180px_220px_130px_160px_minmax(300px,1fr)] gap-4 px-7 py-3 border-b border-[#E5E7EB] bg-[#F9FAFB] sticky top-0">
            {['Timestamp', 'Autor', 'Tipo de Ação', 'Referência', 'Resumo da Alteração'].map(label => (
              <span key={label} className="text-[9px] font-mono text-[#6B7280] uppercase tracking-wider">{label}</span>
            ))}
          </div>
          {filtered.map(entry => (
            <div key={entry.id} className="grid grid-cols-[180px_220px_130px_160px_minmax(300px,1fr)] gap-4 items-center px-7 py-4 border-b border-[#E5E7EB] hover:bg-[#F9FAFB]">
              <span className="text-[11px] font-mono text-[#475569]">
                {new Date(entry.timestamp).toLocaleDateString('pt-PT')} {new Date(entry.timestamp).toLocaleTimeString('pt-PT')}
              </span>
              <div>
                <p className="text-[12px] text-[#1F2937]">{entry.author}</p>
                <div className="mt-1"><RoleBadge role={entry.role} /></div>
              </div>
              <span className="text-[10px] font-mono text-[#475569]">{entry.action}</span>
              <span className="text-[11px] font-mono font-semibold text-[#8A6F14]">{entry.target}</span>
              <span className="text-[12px] text-[#475569] leading-relaxed">{entry.summary}</span>
            </div>
          ))}
          {filtered.length === 0 && (
            <div className="py-20 text-center text-[13px] text-[#64748B]">Sem registos para os filtros selecionados.</div>
          )}
        </div>
      </div>
    </div>
  )
}

function AuditSelect({ label, value, onChange, children }: { label: string; value: string; onChange: (value: string) => void; children: React.ReactNode }) {
  return (
    <label className="space-y-1">
      <span className="block text-[9px] font-mono text-[#6B7280] uppercase">{label}</span>
      <select value={value} onChange={event => onChange(event.target.value)} className="h-9 rounded-md border border-[#D1D5DB] bg-[#FFFFFF] px-3 text-[11px] text-[#1F2937] focus:border-[#C9A227] focus:outline-none">
        {children}
      </select>
    </label>
  )
}

function AuditDate({ label, value, onChange }: { label: string; value: string; onChange: (value: string) => void }) {
  return (
    <label className="space-y-1">
      <span className="block text-[9px] font-mono text-[#6B7280] uppercase">{label}</span>
      <input type="date" value={value} onChange={event => onChange(event.target.value)} className="h-9 rounded-md border border-[#D1D5DB] bg-[#FFFFFF] px-3 text-[11px] text-[#1F2937] focus:border-[#C9A227] focus:outline-none" />
    </label>
  )
}
