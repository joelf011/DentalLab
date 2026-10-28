export type DeadlineFilter = '' | 'urgente' | 'proximo' | 'atrasado'

export const DEADLINE_OPTIONS = [
  { value: '', label: 'Todos os prazos' },
  { value: 'urgente', label: 'Urgentes' },
  { value: 'proximo', label: 'Próximos' },
  { value: 'atrasado', label: 'Atrasados' },
] as const

export function matchesDeadline(
  work: { prazo?: string },
  filter: DeadlineFilter,
): boolean {
  if (!filter || !work.prazo) return true

  const deadline = new Date(work.prazo).getTime()
  const now = Date.now()
  const diffDays = Math.ceil((deadline - now) / 86400000)

  switch (filter) {
    case 'urgente':
      return diffDays >= 0 && diffDays <= 2
    case 'proximo':
      return diffDays >= 0 && diffDays <= 7
    case 'atrasado':
      return diffDays < 0
    default:
      return true
  }
}
