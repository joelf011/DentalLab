import type { User } from '../data'

export default function DesktopNotifications({ user }: { user: User }) {
  const notices = [
    { label: 'Próximos prazos', value: '8 trabalhos' },
    { label: 'Etapas em execução', value: '4 em curso' },
    { label: 'Clínicas ativas', value: String(user.role === 'admin' ? 12 : 5) },
  ]

  return (
    <div className="flex items-center gap-2 rounded-md border border-[#E5E7EB] bg-[#FFFFFF] px-2.5 py-1.5 shadow-sm">
      {notices.map((notice) => (
        <div
          key={notice.label}
          className="flex items-center gap-2 border-l border-[#E5E7EB] first:border-l-0 first:pl-0 pl-2.5"
        >
          <span className="text-[9px] font-mono uppercase tracking-[0.12em] text-[#6B7280]">
            {notice.label}
          </span>
          <span className="text-[11px] font-semibold text-[#1F2937]">
            {notice.value}
          </span>
        </div>
      ))}
    </div>
  )
}
