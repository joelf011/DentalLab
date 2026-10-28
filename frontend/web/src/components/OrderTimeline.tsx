import type { TimelineEvent } from '../data'
import './OrderTimeline.css'

export default function OrderTimeline({ events }: { events: TimelineEvent[] }) {
  const ordered = [...events].sort(
    (a, b) => new Date(a.date).getTime() - new Date(b.date).getTime(),
  )
  const rows = Array.from({ length: Math.ceil(ordered.length / 3) }, (_, i) =>
    ordered.slice(i * 3, i * 3 + 3),
  )
  if (!ordered.length)
    return (
      <p className="text-[13px] text-[var(--muted)] py-6">
        Ainda não existem eventos nesta encomenda.
      </p>
    )
  return (
    <div className="order-timeline" aria-label="Histórico cronológico">
      <p className="text-[12px] text-[var(--muted)] mb-5">
        Do primeiro ao mais recente · siga a numeração.
      </p>
      <div className="timeline-rows">
        {rows.map((row, rowIndex) => {
          const reverse = rowIndex % 2 === 1
          return (
            <div
              className={`timeline-row ${reverse ? 'timeline-reverse' : ''}`}
              key={rowIndex}
            >
              {row.length > 1 && (
                <div
                  aria-hidden="true"
                  className="timeline-horizontal"
                  style={{
                    width: `${((row.length - 1) * 100) / 3}%`,
                    left: reverse ? undefined : '16.6667%',
                    right: reverse ? '16.6667%' : undefined,
                  }}
                />
              )}
              {rowIndex < rows.length - 1 && (
                <div
                  aria-hidden="true"
                  className={`timeline-turn ${
                    reverse ? 'timeline-turn-left' : ''
                  }`}
                />
              )}
              {row.map((event, index) => (
                <article
                  key={event.id}
                  className="timeline-event"
                  style={{
                    gridColumn: reverse ? 3 - index : index + 1,
                    gridRow: 1,
                  }}
                >
                  <div className="timeline-number">
                    {rowIndex * 3 + index + 1}
                  </div>
                  <div className="timeline-card">
                    <p className="text-[13px] font-semibold leading-relaxed">
                      {event.description}
                    </p>
                    <p className="text-[11px] text-[var(--muted)] mt-3 break-words">
                      {event.actor}
                    </p>
                    <time
                      dateTime={event.date}
                      className="block text-[11px] text-[var(--muted)] mt-1"
                    >
                      {new Date(event.date).toLocaleString('pt-PT')}
                    </time>
                  </div>
                </article>
              ))}
            </div>
          )
        })}
      </div>
    </div>
  )
}
