import { useState, type FormEvent } from 'react'
import { NOTES } from '../data'
import { addClientNote, useMockWorkState } from '../mockWorkStore'

export default function ClientConversation({
  workId,
  clinicId,
}: {
  workId: string
  clinicId: string
}) {
  useMockWorkState()
  const [content, setContent] = useState('')
  const [error, setError] = useState('')
  const [sent, setSent] = useState(false)
  const notes = NOTES.filter(
    (n) => n.workId === workId && n.visibility === 'cliente',
  ).sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
  function submit(event: FormEvent) {
    event.preventDefault()
    try {
      addClientNote(workId, clinicId, content)
      setContent('')
      setError('')
      setSent(true)
    } catch (cause) {
      setError(
        cause instanceof Error
          ? cause.message
          : 'Não foi possível enviar a nota.',
      )
    }
  }
  return (
    <section className="space-y-5 text-[var(--ink)]">
      <div>
        <h2 className="text-[16px] font-bold">Comunicação com o laboratório</h2>
        <p className="text-[12px] text-[var(--muted)] mt-1">
          Envie informações ou pedidos de alteração relativos a esta encomenda.
        </p>
      </div>
      <div className="space-y-3" aria-label="Notas partilhadas">
        {!notes.length && (
          <p className="text-[13px] text-[var(--muted)] py-3">
            Ainda não existem notas. Pode iniciar a conversa abaixo.
          </p>
        )}
        {notes.map((note) => (
          <article
            key={note.id}
            className="rounded-xl border border-[var(--line)] bg-[var(--surface)] p-4 break-words"
          >
            <div className="flex flex-wrap items-center justify-between gap-2 mb-2 text-[11px]">
              <strong className="text-[var(--gold-ink)]">
                {note.authorRole === 'clinica' ? 'Clínica' : 'Laboratório'} ·{' '}
                {note.author}
              </strong>
              <time className="text-[var(--muted)]" dateTime={note.date}>
                {new Date(note.date).toLocaleString('pt-PT', {
                  day: '2-digit',
                  month: 'short',
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </time>
            </div>
            <p className="text-[13px] leading-relaxed whitespace-pre-wrap">
              {note.content}
            </p>
          </article>
        ))}
      </div>
      <form
        onSubmit={submit}
        className="rounded-xl border border-[var(--line)] bg-[var(--surface)] p-4 space-y-3"
      >
        <label
          className="block text-[13px] font-semibold"
          htmlFor={`note-${workId}`}
        >
          Adicionar nota
        </label>
        <textarea
          id={`note-${workId}`}
          required
          maxLength={4000}
          rows={4}
          value={content}
          onChange={(e) => {
            setContent(e.target.value)
            setSent(false)
            setError('')
          }}
          placeholder="Escreva a sua mensagem ao laboratório…"
          className="w-full min-w-0 min-h-28 resize-y rounded-lg border border-[var(--line)] bg-[var(--paper)] p-3 text-[13px] focus:outline-2 focus:outline-[var(--gold)]"
        />
        <p className="text-[11px] text-[var(--muted)]">
          Esta nota fica visível para a clínica e para o laboratório.
        </p>
        {error && (
          <p role="alert" className="text-[12px] text-red-600">
            {error}
          </p>
        )}
        {sent && (
          <p role="status" className="text-[12px] text-[var(--gold-ink)]">
            Nota enviada ao laboratório.
          </p>
        )}
        <button
          type="submit"
          disabled={!content.trim()}
          className="min-h-11 w-full sm:w-auto rounded-lg bg-[var(--gold)] px-5 py-3 text-[#181B20] text-[13px] font-bold disabled:opacity-40"
        >
          Enviar nota
        </button>
      </form>
    </section>
  )
}
