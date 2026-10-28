import { AppIcon } from './icons'
import { useEffect, useRef, useState } from 'react'
import type { User, WorkOrder } from '../data'
import { Btn, Modal, Select, Textarea } from './ui'
import {
  getAssignableCollaborators,
  getSequentialSteps,
  type StepTransition,
  type TransitionAssignment,
} from '../workflow'
import { completeMockStep } from '../mockWorkStore'

export function StepCompletionForm({
  work,
  user,
  onClose,
  onDone,
  initialAction = 'advance',
}: {
  work: WorkOrder
  user: User
  onClose: () => void
  onDone: () => void
  initialAction?: StepTransition['action']
}) {
  // Capture the stage being confirmed so a concurrent update cannot advance twice.
  const [sequence] = useState(() => getSequentialSteps(work))
  const [assignment, setAssignment] = useState<TransitionAssignment>('free')
  const [collaboratorId, setCollaboratorId] = useState('')
  const [notes, setNotes] = useState('')
  const [action, setAction] = useState<StepTransition['action']>(initialAction)
  const [reason, setReason] = useState('')
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const { current, next } = sequence

  const confirm = () => {
    if (!current || submitting) return
    setSubmitting(true)
    setError('')
    try {
      completeMockStep(work.id, user, {
        expectedStepId: current.id,
        expectedNextStepId: next?.id,
        assignment,
        collaboratorId,
        notes,
        action,
        reason,
      })
      onDone()
    } catch (cause) {
      setError(
        cause instanceof Error
          ? cause.message
          : 'Não foi possível avançar a etapa.',
      )
      setSubmitting(false)
    }
  }

  if (action === 'standby')
    return (
      <div className="step-completion-form">
        <p className="step-completion-caption">
          Etapa atual:{' '}
          <strong>{current?.name ?? 'Nenhuma etapa em execução'}</strong>
        </p>
        <p className="step-completion-caption">
          Indique o motivo da pausa. A etapa atual fica suspensa, sem avançar
          para a próxima.
        </p>
        <Textarea
          label="Justificação obrigatória"
          value={reason}
          onChange={(value) => {
            setReason(value)
            setError('')
          }}
          placeholder="Explique porque precisa de colocar o trabalho em standby…"
          rows={4}
        />
        {!current && (
          <p role="alert">Assuma uma etapa antes de a colocar em standby.</p>
        )}
        {error && (
          <p role="alert" className="step-completion-error">
            {error}
          </p>
        )}
        <div className="step-completion-actions">
          <Btn variant="ghost" onClick={onClose} disabled={submitting}>
            Cancelar
          </Btn>
          <Btn
            variant="primary"
            onClick={confirm}
            disabled={!current || submitting || !reason.trim()}
          >
            Confirmar Standby
          </Btn>
        </div>
      </div>
    )

  return (
    <div className="step-completion-form">
      <div className="step-completion-summary">
        <p className="step-completion-success">
          Etapa atual:{' '}
          <strong>{current?.name ?? 'Nenhuma etapa em execução'}</strong>
        </p>
        <p className="step-completion-next">
          Próxima Etapa:{' '}
          <strong>
            {next?.name ??
              (current
                ? 'Trabalho concluído — última etapa'
                : 'Por determinar')}
          </strong>
        </p>
      </div>
      {!current && <p role="alert">Assuma uma etapa antes de a concluir.</p>}
      {next && (
        <>
          <Select
            label="Atribuição da Próxima Etapa:"
            value={assignment}
            onChange={(value) => {
              setAssignment(value as TransitionAssignment)
              setError('')
            }}
            options={[
              { value: 'free', label: 'Deixar livre' },
              { value: 'self', label: 'Atribuir a Mim' },
              { value: 'other', label: 'Atribuir a Outro Colaborador' },
            ]}
            required
          />
          {assignment === 'other' && (
            <Select
              label="Colaborador da próxima etapa"
              value={collaboratorId}
              onChange={(value) => {
                setCollaboratorId(value)
                setError('')
              }}
              options={getAssignableCollaborators().map((person) => ({
                value: person.id,
                label: person.name,
              }))}
              required
            />
          )}
        </>
      )}
      <Textarea
        label="Notas de Transição / Observações para a Próxima Etapa"
        value={notes}
        onChange={setNotes}
        placeholder="Opcional — guardado como nota interna"
        rows={3}
      />
      <p className="step-completion-caption">
        <AppIcon
          name="lock"
          className="inline-block align-middle mr-1 h-3.5 w-3.5"
        />{' '}
        Nota de transição: Interna — não visível à clínica.
      </p>
      <details>
        <summary className="step-completion-options">
          Outras opções: prova clínica ou standby
        </summary>
        <Select
          label="Destino"
          value={action}
          onChange={(value) => {
            setAction(value as StepTransition['action'])
            setError('')
          }}
          options={[
            { value: 'advance', label: 'Avançar na sequência de produção' },
            { value: 'clinic', label: 'Enviar para Prova Clínica' },
            { value: 'standby', label: 'Colocar em standby' },
          ]}
        />
      </details>
      {error && (
        <p role="alert" className="step-completion-error">
          {error}
        </p>
      )}
      <div className="step-completion-actions">
        <Btn variant="ghost" onClick={onClose} disabled={submitting}>
          Cancelar
        </Btn>
        <Btn
          variant="primary"
          onClick={confirm}
          disabled={!current || submitting}
        >
          Confirmar e Avançar Etapa
        </Btn>
      </div>
    </div>
  )
}

export default function StepCompletion({
  work,
  user,
  onClose,
  onDone,
  mobile = false,
  initialAction = 'advance',
}: {
  work: WorkOrder
  user: User
  onClose: () => void
  onDone: () => void
  mobile?: boolean
  initialAction?: StepTransition['action']
}) {
  const containerRef = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const root = containerRef.current
    if (!root) return
    const dialog = root.querySelector<HTMLElement>('[role="dialog"]') ?? root
    const previousFocus = document.activeElement as HTMLElement | null
    const focusable = () =>
      Array.from(
        dialog.querySelectorAll<HTMLElement>(
          'button:not([disabled]), select:not([disabled]), textarea:not([disabled]), summary',
        ),
      ).filter((element) => element.getClientRects().length > 0)
    focusable()[0]?.focus()
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') {
        event.preventDefault()
        onClose()
      }
      if (event.key !== 'Tab') return
      const targets = focusable()
      const first = targets[0]
      const last = targets[targets.length - 1]
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last?.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first?.focus()
      }
    }
    root.addEventListener('keydown', handleKeyDown)
    return () => {
      root.removeEventListener('keydown', handleKeyDown)
      if (previousFocus?.isConnected) previousFocus.focus()
    }
  }, [onClose])
  const title =
    initialAction === 'standby' ? 'Colocar em standby' : 'Concluir Etapa'
  const form = (
    <StepCompletionForm
      work={work}
      user={user}
      onClose={onClose}
      onDone={onDone}
      initialAction={initialAction}
    />
  )
  if (mobile)
    return (
      <div ref={containerRef} className="step-completion-overlay">
        <button
          type="button"
          className="step-completion-backdrop"
          aria-label={`Cancelar: ${title}`}
          onClick={onClose}
        />
        <div
          role="dialog"
          aria-modal="true"
          aria-label={`${title} — ${work.ref}`}
          className="completion-sheet step-completion-sheet"
        >
          <h2>{title}</h2>
          <p className="step-completion-caption">{work.ref}</p>
          {form}
        </div>
      </div>
    )
  return (
    <div
      ref={containerRef}
      role="dialog"
      aria-modal="true"
      aria-label={`${title} — ${work.ref}`}
    >
      <Modal title={title} subtitle={work.ref} onClose={onClose}>
        {form}
      </Modal>
    </div>
  )
}
