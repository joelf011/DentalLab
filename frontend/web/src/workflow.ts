import {
  COLABORADORES,
  type User,
  type WorkOrder,
  type WorkOrderStep,
} from './data'

export type StepTransitionAction = 'advance' | 'clinic' | 'standby'
export type StepTransition = {
  action: StepTransitionAction
}

export type TransitionAssignment = 'free' | 'self' | 'other'

export function getSequentialSteps(work: WorkOrder) {
  const steps = work.steps ?? []
  const current =
    steps.find((step) => step.status === 'em_execucao') ??
    steps.find((step) => step.status === 'standby') ??
    steps.find((step) => step.status === 'nao_iniciado')

  const currentIndex = current
    ? steps.findIndex((step) => step.id === current.id)
    : -1
  const next = currentIndex >= 0 ? steps[currentIndex + 1] : undefined

  return { current, next }
}

export function getAssignableCollaborators() {
  return COLABORADORES.filter((person) => person.role === 'colaborador').map(
    (person) => ({
      id: person.id,
      name: person.name,
      role: person.role,
      status: person.status,
    }),
  )
}

export function canManageMockStep(work: WorkOrder, user: User): boolean {
  if (user.role === 'admin') return true
  if (work.responsavelId === user.id) return true
  return false
}

export function isMockWorkClaimable(work: WorkOrder): boolean {
  return work.status !== 'concluido' && !work.responsavelId
}

export function claimMockStep(workId: string, user: User, _stepId?: string) {
  const work = {
    id: workId,
    responsavelId: user.id,
    responsavelName: user.name,
  }
  return work
}

export function completeMockStep(
  workId: string,
  _user: User,
  _payload: Record<string, unknown>,
) {
  return {
    id: workId,
    ok: true,
  }
}

export type StepSequence = {
  current?: WorkOrderStep
  next?: WorkOrderStep
}
