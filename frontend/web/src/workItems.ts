export function updateWorkItem<T extends { id: string }>(
  items: T[],
  id: string,
  patch: Partial<T>,
): T[] {
  return items.map((item) => (item.id === id ? { ...item, ...patch } : item))
}

export function finalizeWorkItems<T extends { id: string }>(items: T[]): T[] {
  return items.map((item) => ({ ...item }))
}
