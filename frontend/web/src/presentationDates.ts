export function presentationDate(daysOffset = 0, time = '00:00:00') {
  const date = new Date()
  date.setDate(date.getDate() + daysOffset)

  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')

  return `${year}-${month}-${day}T${time}`
}
