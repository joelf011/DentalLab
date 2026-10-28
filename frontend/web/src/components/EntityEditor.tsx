import { useState, type FormEvent } from 'react'
import type { Cliente, Colaborador } from '../data'
import { saveMockClient, saveMockCollaborator } from '../mockWorkStore'
import { Modal } from './ui'

type Props =
  | {
      kind: 'client'
      value?: Cliente
      onSaved: (value: Cliente) => void
      onClose: () => void
    }
  | {
      kind: 'collaborator'
      value?: Colaborador
      onSaved: (value: Colaborador) => void
      onClose: () => void
    }

export default function EntityEditor(props: Props) {
  const client = props.kind === 'client'
  const [values, setValues] = useState<Record<string, string>>({
    name: props.value?.name ?? '',
    email: props.value?.email ?? '',
    nif: client ? (props.value?.nif ?? '') : '',
    phone: client ? (props.value?.phone ?? '') : '',
    address: client ? (props.value?.address ?? '') : '',
  })
  const [error, setError] = useState('')
  const fields = client
    ? [
        ['name', 'Nome da clínica / consultório'],
        ['nif', 'NIF'],
        ['email', 'E-mail'],
        ['phone', 'Telefone'],
        ['address', 'Morada'],
      ]
    : [
        ['name', 'Nome completo'],
        ['email', 'E-mail'],
      ]
  function submit(event: FormEvent) {
    event.preventDefault()
    try {
      if (props.kind === 'client') {
        props.onSaved(
          saveMockClient(
            {
              id: props.value?.id,
              name: values.name,
              email: values.email,
              nif: values.nif,
              phone: values.phone,
              address: values.address,
              status: props.value?.status ?? 'ativo',
              activeWorks: props.value?.activeWorks ?? 0,
              registeredAt:
                props.value?.registeredAt ?? new Date().toISOString(),
            },
            props.value?.id,
          ),
        )
      } else {
        props.onSaved(
          saveMockCollaborator(
            {
              id: props.value?.id,
              name: values.name,
              email: values.email,
              role: props.value?.role ?? 'colaborador',
              status: props.value?.status ?? 'disponivel',
              activeWorks: props.value?.activeWorks ?? 0,
              completedThisMonth: props.value?.completedThisMonth ?? 0,
              joinedAt: props.value?.joinedAt ?? new Date().toISOString(),
            },
            props.value?.id,
          ),
        )
      }
    } catch (cause) {
      setError(
        cause instanceof Error ? cause.message : 'Não foi possível guardar.',
      )
    }
  }
  return (
    <Modal
      title={`${props.value ? 'Editar' : 'Novo'} ${
        client ? 'cliente' : 'colaborador'
      }`}
      onClose={props.onClose}
    >
      <form onSubmit={submit} className="p-5 space-y-4">
        {fields.map(([key, label]) => (
          <label key={key} className="block text-[12px] text-[var(--ink)]">
            <span className="block mb-2 font-medium">
              {label}
              {key !== 'phone' ? ' *' : ''}
            </span>
            <input
              autoFocus={key === 'name'}
              required={key !== 'phone'}
              type={
                key === 'email' ? 'email' : key === 'phone' ? 'tel' : 'text'
              }
              value={values[key]}
              onChange={(e) =>
                setValues((previous) => ({
                  ...previous,
                  [key]: e.target.value,
                }))
              }
              className="w-full min-h-11 px-3 py-2 rounded-lg border border-[var(--line)] bg-[var(--surface)] text-[var(--ink)] focus:outline-2 focus:outline-[var(--gold)]"
            />
          </label>
        ))}
        {!props.value && (
          <p className="text-[12px] text-[var(--muted)]">
            {client
              ? 'O cliente criado pela administração fica ativo.'
              : 'O novo colaborador fica disponível para atribuição de etapas.'}
          </p>
        )}
        {error && (
          <p role="alert" className="text-[12px] text-red-600">
            {error}
          </p>
        )}
        <div className="flex justify-end gap-3 pt-2">
          <button
            type="button"
            onClick={props.onClose}
            className="min-h-11 px-4 text-[var(--muted)]"
          >
            Cancelar
          </button>
          <button
            type="submit"
            className="min-h-11 px-5 rounded-lg bg-[var(--gold)] text-[#181B20] font-semibold text-[13px]"
          >
            {props.value ? 'Guardar alterações' : 'Criar'}
          </button>
        </div>
      </form>
    </Modal>
  )
}
