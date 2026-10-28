import { useState } from 'react'
import {
  NOTES,
  WORK_ORDERS,
  type InternalNote,
  type WorkOrder,
  type User,
} from './data'

let mockRevision = 0
const noteBuffer: InternalNote[] = [...NOTES]

function bumpRevision() {
  mockRevision += 1
}

export function useMockWorkState() {
  const [revision] = useState(mockRevision)
  return revision
}

export function updateMockWork<T extends WorkOrder>(
  id: string,
  updater: (work: T) => T,
): T | null {
  const work = WORK_ORDERS.find((entry) => entry.id === id) as T | undefined
  if (!work) return null

  const next = updater(work)
  Object.assign(work, next)
  bumpRevision()
  return next
}

export function updateMockNotes(
  updater: (previous: InternalNote[]) => InternalNote[],
): InternalNote[] {
  const next = updater(noteBuffer)
  noteBuffer.splice(0, noteBuffer.length, ...next)
  bumpRevision()
  return [...noteBuffer]
}

export function setMockClientStatus(_id: string, _action: string) {
  bumpRevision()
}

export function setMockCollaboratorAbsent(_id: string, _absent: boolean) {
  bumpRevision()
}

export function softDeleteMockCollaborator(_id: string) {
  bumpRevision()
}

export function saveMockClient(
  client: Partial<import('./data').Cliente> & { id?: string },
  id?: string,
) {
  const persisted: import('./data').Cliente = {
    id: id ?? client.id ?? `client-${Date.now()}`,
    name: client.name ?? '',
    nif: client.nif ?? '',
    email: client.email ?? '',
    phone: client.phone ?? '',
    address: client.address ?? '',
    status: client.status ?? 'ativo',
    activeWorks: client.activeWorks ?? 0,
    registeredAt: client.registeredAt ?? new Date().toISOString(),
  }
  bumpRevision()
  return persisted
}

export function saveMockCollaborator(
  collaborator: Partial<import('./data').Colaborador> & { id?: string },
  id?: string,
) {
  const persisted: import('./data').Colaborador = {
    id: id ?? collaborator.id ?? `col-${Date.now()}`,
    name: collaborator.name ?? '',
    email: collaborator.email ?? '',
    role: collaborator.role ?? 'colaborador',
    status: collaborator.status ?? 'disponivel',
    activeWorks: collaborator.activeWorks ?? 0,
    completedThisMonth: collaborator.completedThisMonth ?? 0,
    joinedAt: collaborator.joinedAt ?? new Date().toISOString(),
  }
  bumpRevision()
  return persisted
}

export function getClientEvents(_workId: string) {
  return [] as Array<import('./data').TimelineEvent>
}

export function addClientNote(
  _workId: string,
  _clinicId: string,
  _content: string,
) {
  bumpRevision()
  return true
}

export function canManageMockStep(work: WorkOrder, user: User): boolean {
  if (user.role === 'admin') return true
  return work.responsavelId === user.id
}

export function isMockWorkClaimable(work: WorkOrder): boolean {
  return !work.responsavelId && work.status !== 'concluido'
}

export function claimMockStep(workId: string, user: User, _stepId?: string) {
  const work = WORK_ORDERS.find((entry) => entry.id === workId)
  if (!work) return null

  work.responsavelId = user.id
  work.responsavelName = user.name
  bumpRevision()
  return work
}

export function completeMockStep(
  _workId: string,
  _user: User,
  _payload: unknown,
) {
  bumpRevision()
  return true
}
