import { AppIcon } from '../../components/icons'
import { useState, type ReactNode } from 'react'
import { CLIENTES, WORK_TYPES, type WorkNature } from '../../data'
import { finalizeWorkItems, updateWorkItem } from '../../workItems'

const UPPER_TEETH = [
  18, 17, 16, 15, 14, 13, 12, 11, 21, 22, 23, 24, 25, 26, 27, 28,
]
const LOWER_TEETH = [
  48, 47, 46, 45, 44, 43, 42, 41, 31, 32, 33, 34, 35, 36, 37, 38,
]

interface OrderData {
  doctor: string
  patientId: string
  age: string
  sex: 'masculino' | 'feminino' | 'outro' | ''
}

interface JobData {
  id: string
  typeId: string
  nature: WorkNature | ''
  color: string
  teeth: number[]
  description: string
  files: string[]
  photos: string[]
}

interface ClinicDesktopNewOrderProps {
  admin?: boolean
  onCancel: () => void
  onDone: () => void
}

const createEmptyJob = (): JobData => ({
  id: `job-${Date.now()}-${Math.random()}`,
  typeId: WORK_TYPES[0]?.id ?? '',
  nature: WORK_TYPES[0]?.nature ?? '',
  color: '',
  teeth: [],
  description: '',
  files: [],
  photos: [],
})

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div className="space-y-2">
      <label className="text-[11px] font-mono text-[#64748B] uppercase tracking-wider">
        {label}
      </label>
      {children}
    </div>
  )
}

function ProgressBar({ current }: { current: number }) {
  return (
    <div className="flex items-center gap-1.5">
      {[1, 2].map((item) => (
        <div
          key={item}
          className={`h-1.5 flex-1 rounded-full transition-colors ${
            item <= current ? 'bg-[#C9A227]' : 'bg-[#E5E7EB]'
          }`}
        />
      ))}
    </div>
  )
}

function Odontogram({
  selected,
  onChange,
}: {
  selected: number[]
  onChange: (teeth: number[]) => void
}) {
  const toggle = (tooth: number) => {
    onChange(
      selected.includes(tooth)
        ? selected.filter((item) => item !== tooth)
        : [...selected, tooth],
    )
  }

  const Tooth = ({ tooth, lower }: { tooth: number; lower?: boolean }) => {
    const isSelected = selected.includes(tooth)
    const position = tooth % 10
    const type =
      position <= 2
        ? 'incisor'
        : position === 3
          ? 'canine'
          : position <= 5
            ? 'premolar'
            : 'molar'
    const paths = {
      incisor:
        'M9 3 C9 3 10.5 1.5 12 1.5 C13.5 1.5 15 3 15 3 L15.5 18 C19 20 20.5 25 19.5 32 C18.5 39 16 42 12 42 C8 42 5.5 39 4.5 32 C3.5 25 5 20 8.5 18 Z',
      canine:
        'M10 2 C10.5 0.5 13.5 0.5 14 2 L15.5 20 C19 22 20 27 18.5 33 C17 39 14.5 42 12 43 C9.5 42 7 39 5.5 33 C4 27 5 22 8.5 20 Z',
      premolar:
        'M6.5 4 C7 1.5 9 1 10.5 3 L12 15 L13.5 3 C15 1 17 1.5 17.5 4 L16.5 19 C20 21 21 26 19.5 33 C18 39 15.5 42 12 42 C8.5 42 6 39 4.5 33 C3 26 4 21 7.5 19 Z',
      molar:
        'M4 5 C4.5 2 7 1 8.5 4 L10 15 L11 3 C11.5 1 13 1 13.5 3 L14.5 15 L16 4 C17.5 1 20 2 20 5 L18.5 20 C21.5 23 22 28 20.5 34 C19 40 16 42 12 42 C8 42 5 40 3.5 34 C2 28 2.5 23 5.5 20 Z',
    }

    return (
      <button
        type="button"
        onClick={() => toggle(tooth)}
        aria-pressed={isSelected}
        aria-label={`Dente ${tooth}${isSelected ? ', selecionado' : ''}`}
        className="group flex-1 min-w-0 max-w-10 flex flex-col items-center rounded-lg px-0.5 py-1 transition-all hover:bg-[#FFFFFF] focus:outline-none focus-visible:ring-2 focus-visible:ring-[#C9A227]/50"
      >
        {!lower && (
          <span
            className={`text-[9px] font-mono leading-none mb-1.5 transition-colors ${
              isSelected
                ? 'text-[#8A6F14] font-semibold'
                : 'text-[#64748B] group-hover:text-[#1F2937]'
            }`}
          >
            {tooth}
          </span>
        )}
        <svg
          viewBox="0 0 24 44"
          className="w-full h-14 overflow-visible"
          aria-hidden="true"
        >
          <g transform={lower ? 'rotate(180 12 22)' : undefined}>
            <path
              d={paths[type]}
              fill={isSelected ? '#E7C95D' : '#FFFEF8'}
              stroke={isSelected ? '#9A7A16' : '#94A3B8'}
              strokeWidth={isSelected ? '1.5' : '1.1'}
              strokeLinejoin="round"
              className="transition-colors"
            />
            <path
              d={
                type === 'molar'
                  ? 'M6.5 25 C9 23 15 23 17.5 25 M7 31 C10 29 14 29 17 31'
                  : 'M7.5 26 C10 24.5 14 24.5 16.5 26'
              }
              fill="none"
              stroke={isSelected ? '#B58F1E' : '#D1D5DB'}
              strokeWidth="0.8"
              strokeLinecap="round"
            />
          </g>
          {isSelected && (
            <g>
              <circle
                cx="12"
                cy={lower ? 13.5 : 30.5}
                r="5"
                fill="#FFFFFF"
                fillOpacity="0.94"
              />
              <path
                d={`M9 ${lower ? 13.5 : 30.5} L11.2 ${
                  lower ? 15.5 : 32.5
                } L15.2 ${lower ? 11.5 : 28.5}`}
                fill="none"
                stroke="#8A6F14"
                strokeWidth="1.8"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </g>
          )}
        </svg>
        {lower && (
          <span
            className={`text-[9px] font-mono leading-none mt-1.5 transition-colors ${
              isSelected
                ? 'text-[#8A6F14] font-semibold'
                : 'text-[#64748B] group-hover:text-[#1F2937]'
            }`}
          >
            {tooth}
          </span>
        )}
      </button>
    )
  }

  return (
    <div className="bg-gradient-to-b from-[#FFFFFF] to-[#F9FAFB] border border-[#E5E7EB] rounded-xl px-6 py-5 overflow-x-auto">
      <div className="flex flex-wrap items-center gap-2 mb-3">
        <button
          type="button"
          onClick={() => onChange([...UPPER_TEETH, ...LOWER_TEETH])}
          className="min-h-11 px-3 rounded-lg bg-[var(--gold)] text-[#181B20] text-[12px] font-semibold"
        >
          Selecionar todos
        </button>
        <button
          type="button"
          onClick={() => onChange([])}
          disabled={!selected.length}
          className="min-h-11 px-3 rounded-lg border border-[var(--line)] text-[var(--ink)] text-[12px] disabled:opacity-40"
        >
          Limpar seleção
        </button>
      </div>
      <div className="min-w-[680px] max-w-4xl mx-auto">
        <div className="grid grid-cols-2 mb-2 px-8">
          <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest text-center">
            Superior direito
          </span>
          <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest text-center">
            Superior esquerdo
          </span>
        </div>

        <div className="flex items-end justify-center gap-1">
          {UPPER_TEETH.map((tooth) => (
            <Tooth key={tooth} tooth={tooth} />
          ))}
        </div>

        <div className="flex items-center gap-4 my-3 px-4">
          <div className="h-px flex-1 bg-gradient-to-r from-transparent via-[#D1D5DB] to-[#D1D5DB]" />
          <span className="text-[8px] font-mono text-[#9CA3AF] uppercase tracking-widest">
            Linha oclusal
          </span>
          <div className="h-px flex-1 bg-gradient-to-l from-transparent via-[#D1D5DB] to-[#D1D5DB]" />
        </div>

        <div className="flex items-start justify-center gap-1">
          {LOWER_TEETH.map((tooth) => (
            <Tooth key={tooth} tooth={tooth} lower />
          ))}
        </div>

        <div className="grid grid-cols-2 mt-2 px-8">
          <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest text-center">
            Inferior direito
          </span>
          <span className="text-[9px] font-mono text-[#9CA3AF] uppercase tracking-widest text-center">
            Inferior esquerdo
          </span>
        </div>
      </div>

      <div className="flex items-center justify-between gap-4 mt-5 pt-4 border-t border-[#E5E7EB]">
        <div className="flex items-center gap-2">
          <span className="w-3 h-3 rounded-sm bg-[#E7C95D] border border-[#9A7A16]" />
          <span className="text-[11px] text-[#64748B]">
            Selecione os dentes aplicáveis
          </span>
        </div>
        <span className="text-[11px] font-mono text-[#8A6F14]">
          {selected.length > 0
            ? `Selecionados: ${[...selected].sort((a, b) => a - b).join(', ')}`
            : 'Nenhum selecionado'}
        </span>
      </div>
    </div>
  )
}

function UploadArea({
  label,
  description,
  accept,
  files,
  onChange,
  accent,
}: {
  label: string
  description: string
  accept: string
  files: string[]
  onChange: (files: string[]) => void
  accent?: boolean
}) {
  const addFiles = (incoming: FileList | null) => {
    if (!incoming) return
    const validNames = Array.from(incoming)
      .filter((file) =>
        accept === 'image/*'
          ? file.type.startsWith('image/')
          : /\.(zip|stl)$/i.test(file.name),
      )
      .map((file) => file.name)
    onChange([...new Set([...files, ...validNames])])
  }

  return (
    <label
      onDragOver={(event) => event.preventDefault()}
      onDrop={(event) => {
        event.preventDefault()
        addFiles(event.dataTransfer.files)
      }}
      className={`min-h-44 border-2 border-dashed rounded-xl p-6 flex flex-col items-center justify-center gap-2 text-center cursor-pointer transition-colors ${
        accent
          ? 'border-[#C9A227]/40 bg-[#C9A227]/5 hover:bg-[#C9A227]/10'
          : 'border-[#D1D5DB] bg-[#FFFFFF] hover:bg-slate-50'
      }`}
    >
      <input
        type="file"
        accept={accept}
        multiple
        onChange={(event) => addFiles(event.target.files)}
        className="sr-only"
      />
      <span
        className={`w-10 h-10 rounded-full flex items-center justify-center text-lg ${
          accent
            ? 'bg-[#C9A227]/15 text-[#8A6F14]'
            : 'bg-slate-100 text-[#64748B]'
        }`}
      >
        <AppIcon
          name={accept === 'image/*' ? 'camera' : 'upload'}
          className="h-5 w-5"
        />
      </span>
      <p className="text-[12px] font-semibold text-[#1F2937]">{label}</p>
      <p className="text-[10px] text-[#64748B]">{description}</p>
      {files.length > 0 && (
        <div className="w-full mt-2 pt-3 border-t border-[#E5E7EB] space-y-1">
          {files.map((file) => (
            <p key={file} className="text-[10px] text-[#475569] truncate">
              {file}
            </p>
          ))}
        </div>
      )}
    </label>
  )
}

export default function ClinicDesktopNewOrder({
  onCancel,
  onDone,
  admin = false,
}: ClinicDesktopNewOrderProps) {
  const [clinicId, setClinicId] = useState('')
  const [step, setStep] = useState<1 | 2>(1)
  const [submitted, setSubmitted] = useState(false)
  const [orderReference, setOrderReference] = useState('')
  const [order, setOrder] = useState<OrderData>({
    doctor: '',
    patientId: '',
    age: '',
    sex: '',
  })
  const [jobs, setJobs] = useState<JobData[]>(() => [createEmptyJob()])
  const [openJobId, setOpenJobId] = useState<string | null>(() => jobs[0].id)
  const currentProgress = step

  const setJobField = <K extends keyof JobData>(
    id: string,
    key: K,
    value: JobData[K],
  ) => {
    setJobs((previous) =>
      updateWorkItem(previous, id, { [key]: value } as Partial<JobData>),
    )
  }

  const addJob = () => {
    const job = createEmptyJob()
    setJobs((previous) => [...previous, job])
    setOpenJobId(job.id)
  }

  const submitOrder = () => {
    const year = new Date().getFullYear()
    setJobs((previous) => finalizeWorkItems(previous))
    setOrderReference(
      `ENC-${year}-${String(Math.floor(Math.random() * 900) + 100)}`,
    )
    setSubmitted(true)
  }

  if (submitted) {
    const jobCount = jobs.length
    return (
      <div className="flex-1 overflow-y-auto">
        <div className="min-h-full flex items-center justify-center p-7">
          <div className="w-full max-w-xl text-center">
            <div className="w-20 h-20 rounded-full bg-[#C9A227]/15 border border-[#C9A227]/30 flex items-center justify-center mx-auto mb-6">
              <span className="text-[#8A6F14] text-3xl">✓</span>
            </div>
            <p className="text-[26px] font-serif text-[#1F2937]">
              Encomenda enviada
            </p>
            <p className="text-[13px] text-[#475569] mt-2">
              A encomenda e os respetivos trabalhos foram enviados para análise
              do laboratório.
            </p>
            <div className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-5 mt-6 text-left space-y-3">
              {[
                ...(admin
                  ? [
                      [
                        'Clínica',
                        CLIENTES.find((clinic) => clinic.id === clinicId)
                          ?.name || '—',
                      ],
                    ]
                  : []),
                ['Referência', orderReference],
                ['Identificação', order.patientId],
                ['Médico responsável', order.doctor || '—'],
                ['Idade', order.age ? `${order.age} anos` : '—'],
                ['Sexo', order.sex || '—'],
                [
                  'Trabalhos',
                  `${jobCount} trabalho${jobCount !== 1 ? 's' : ''}`,
                ],
              ].map(([label, value]) => (
                <div
                  key={label}
                  className="flex items-center justify-between gap-4"
                >
                  <span className="text-[11px] text-[#64748B]">{label}</span>
                  <span className="text-[12px] text-[#1F2937] font-medium">
                    {value}
                  </span>
                </div>
              ))}
            </div>
            <button
              onClick={onDone}
              className="w-full mt-6 py-3.5 bg-[#C9A227] text-[#1F2937] text-[14px] font-semibold rounded-xl hover:bg-[#D4AF37] transition-colors"
            >
              Ver Encomendas
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="p-4 md:p-7 max-w-[1100px] space-y-6">
        <div className="flex items-start justify-between gap-6">
          <div>
            <p className="text-[10px] font-mono text-[#64748B] uppercase tracking-wider">
              Passo {step} de 2
            </p>
            <p className="text-[24px] font-serif text-[#1F2937] mt-1">
              {step === 1 ? 'Nova Encomenda' : 'Trabalhos da Encomenda'}
            </p>
          </div>
          <button
            onClick={onCancel}
            className="px-3 py-2 text-[12px] text-[#64748B] border border-[#E5E7EB] bg-[#FFFFFF] rounded-md hover:text-[#1F2937] transition-colors"
          >
            Cancelar
          </button>
        </div>

        <ProgressBar current={currentProgress} />

        {step === 1 && (
          <div className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-6 space-y-6">
            <p className="text-[13px] text-[#475569]">
              Indique apenas os dados essenciais para identificar o paciente.
            </p>

            {admin && (
              <Field label="Clínica">
                <select
                  aria-label="Clínica"
                  value={clinicId}
                  onChange={(event) => setClinicId(event.target.value)}
                  className="w-full px-4 py-3.5 border border-[var(--line)] rounded-xl bg-[var(--surface)] text-[var(--ink)]"
                >
                  <option value="">Selecionar clínica...</option>
                  {CLIENTES.filter((clinic) => clinic.status === 'ativo').map(
                    (clinic) => (
                      <option key={clinic.id} value={clinic.id}>
                        {clinic.name}
                      </option>
                    ),
                  )}
                </select>
              </Field>
            )}
            <Field label="Médico responsável">
              <input
                aria-label="Médico responsável"
                value={order.doctor}
                onChange={(event) =>
                  setOrder((previous) => ({
                    ...previous,
                    doctor: event.target.value,
                  }))
                }
                placeholder="Nome do médico responsável por esta encomenda"
                className="w-full px-4 py-3.5 bg-[#FFFFFF] border border-[#D1D5DB] rounded-xl text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227] focus:outline-none"
              />
            </Field>

            <Field label="Identificação">
              <input
                value={order.patientId}
                onChange={(event) =>
                  setOrder((previous) => ({
                    ...previous,
                    patientId: event.target.value,
                  }))
                }
                placeholder="Nome, referência ou código interno"
                className="w-full px-4 py-3.5 bg-[#FFFFFF] border border-[#D1D5DB] rounded-xl text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227] focus:outline-none"
              />
            </Field>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <Field label="Idade">
                <input
                  type="number"
                  min="0"
                  max="120"
                  value={order.age}
                  onChange={(event) =>
                    setOrder((previous) => ({
                      ...previous,
                      age: event.target.value,
                    }))
                  }
                  placeholder="Anos"
                  className="w-full px-4 py-3.5 bg-[#FFFFFF] border border-[#D1D5DB] rounded-xl text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227] focus:outline-none"
                />
              </Field>

              <Field label="Sexo">
                <select
                  value={order.sex}
                  onChange={(event) =>
                    setOrder((previous) => ({
                      ...previous,
                      sex: event.target.value as OrderData['sex'],
                    }))
                  }
                  className="w-full px-4 py-3.5 bg-[#FFFFFF] border border-[#D1D5DB] rounded-xl text-[13px] text-[#1F2937] focus:border-[#C9A227] focus:outline-none appearance-none"
                >
                  <option value="">Selecionar...</option>
                  <option value="masculino">Masculino</option>
                  <option value="feminino">Feminino</option>
                  <option value="outro">Outro</option>
                </select>
              </Field>
            </div>

            <div className="flex justify-end pt-2">
              <button
                disabled={admin && !clinicId}
                onClick={() => setStep(2)}
                className="disabled:opacity-50 px-8 py-3.5 bg-[#C9A227] text-[#1F2937] text-[14px] font-semibold rounded-xl hover:bg-[#D4AF37] transition-colors"
              >
                Continuar
              </button>
            </div>
          </div>
        )}

        {step === 2 && (
          <div className="space-y-5">
            <div className="overflow-hidden rounded-xl border border-[var(--line)] bg-[var(--surface)] divide-y divide-[var(--line)]">
              {jobs.map((job, index) => {
                const expanded = openJobId === job.id
                return (
                  <section key={job.id}>
                    <div className="flex items-center gap-3 px-5 py-4">
                      <button
                        type="button"
                        onClick={() => setOpenJobId(expanded ? null : job.id)}
                        className="flex min-w-0 flex-1 items-center justify-between gap-4 text-left"
                      >
                        <span>
                          <span className="block text-[10px] font-mono font-bold uppercase text-[var(--muted)]">
                            Trabalho {index + 1}
                          </span>
                          <span className="block text-[14px] font-semibold text-[var(--ink)]">
                            {WORK_TYPES.find((type) => type.id === job.typeId)
                              ?.name || 'Selecionar tipo'}
                          </span>
                        </span>
                        <span className="text-[18px] text-[var(--gold-ink)]">
                          {expanded ? '−' : '+'}
                        </span>
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          const remaining = jobs.filter(
                            (item) => item.id !== job.id,
                          )
                          if (remaining.length === 0) {
                            const replacement = createEmptyJob()
                            setJobs([replacement])
                            setOpenJobId(replacement.id)
                          } else {
                            setJobs(remaining)
                            if (expanded) setOpenJobId(remaining[0].id)
                          }
                        }}
                        className="text-[11px] font-semibold text-red-700"
                      >
                        Remover
                      </button>
                    </div>
                    {expanded && (
                      <div className="space-y-6 border-t border-[var(--line)] p-6">
                        <Field label="Tipo de trabalho">
                          <select
                            value={job.typeId}
                            onChange={(event) => {
                              const type = WORK_TYPES.find(
                                (item) => item.id === event.target.value,
                              )
                              setJobs((previous) =>
                                previous.map((item) =>
                                  item.id === job.id
                                    ? {
                                        ...item,
                                        typeId: event.target.value,
                                        nature: type?.nature ?? '',
                                      }
                                    : item,
                                ),
                              )
                            }}
                            className="w-full px-4 py-3.5 bg-[#FFFFFF] border border-[#D1D5DB] rounded-xl text-[13px] text-[#1F2937] focus:border-[#C9A227] focus:outline-none appearance-none"
                          >
                            {WORK_TYPES.map((type) => (
                              <option key={type.id} value={type.id}>
                                {type.name}
                              </option>
                            ))}
                          </select>
                        </Field>
                        {
                          <>
                            <Field label="Odontograma">
                              <Odontogram
                                selected={job.teeth}
                                onChange={(value) =>
                                  setJobField(job.id, 'teeth', value)
                                }
                              />
                            </Field>
                            <Field label="Cor">
                              <input
                                value={job.color}
                                onChange={(event) =>
                                  setJobField(
                                    job.id,
                                    'color',
                                    event.target.value,
                                  )
                                }
                                placeholder="Ex: A2"
                                className="w-full px-4 py-3.5 bg-[#FFFFFF] border border-[#D1D5DB] rounded-xl text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227] focus:outline-none"
                              />
                            </Field>
                          </>
                        }
                        <Field label="Descrição do trabalho">
                          <textarea
                            value={job.description}
                            onChange={(event) =>
                              setJobField(
                                job.id,
                                'description',
                                event.target.value,
                              )
                            }
                            placeholder="Especificações e indicações para este trabalho..."
                            rows={4}
                            className="w-full px-4 py-3.5 bg-[#FFFFFF] border border-[#D1D5DB] rounded-xl text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227] focus:outline-none resize-none"
                          />
                        </Field>
                        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                          <UploadArea
                            label="Ficheiros STL ou ZIP"
                            description="Selecione os ficheiros digitais"
                            accept=".zip,.stl"
                            files={job.files}
                            onChange={(value) =>
                              setJobField(job.id, 'files', value)
                            }
                            accent
                          />
                          <UploadArea
                            label="Fotografias"
                            description="Fotografias clínicas ou de apoio"
                            accept="image/*"
                            files={job.photos}
                            onChange={(value) =>
                              setJobField(job.id, 'photos', value)
                            }
                          />
                        </div>
                      </div>
                    )}
                  </section>
                )
              })}
            </div>
            <button
              onClick={addJob}
              className="w-full py-3.5 bg-[#FFFFFF] border border-[#C9A227] text-[#8A6F14] text-[13px] font-semibold rounded-xl hover:bg-[#C9A227]/10 transition-colors"
            >
              + Adicionar trabalho
            </button>
            <div className="flex items-center justify-between pb-4">
              <button
                onClick={() => setStep(1)}
                className="px-5 py-3 text-[13px] text-[#64748B] hover:text-[#1F2937]"
              >
                Voltar
              </button>
              <button
                onClick={submitOrder}
                disabled={jobs.some((job) => !job.typeId)}
                className="disabled:opacity-50 px-8 py-3.5 bg-[#C9A227] text-[#1F2937] text-[14px] font-semibold rounded-xl disabled:opacity-50"
              >
                Enviar Encomenda · {jobs.length} trabalho
                {jobs.length !== 1 ? 's' : ''}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
