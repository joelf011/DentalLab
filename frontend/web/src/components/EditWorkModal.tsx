import { useState } from 'react'
import type { WorkOrder } from '../data'
import { Btn, Input, Modal, Textarea } from './ui'

export interface EditableWorkMetadata {
  identificadorPaciente: string
  medico: string
  material: string
  cor: string
  prazo: string
  proximaConsulta: string
  descricao: string
}

export default function EditWorkModal({
  work,
  onClose,
  onSave,
}: {
  work: WorkOrder
  onClose: () => void
  onSave: (metadata: EditableWorkMetadata) => void
}) {
  const [metadata, setMetadata] = useState<EditableWorkMetadata>({
    identificadorPaciente: work.identificadorPaciente,
    medico: work.medico,
    material: work.material,
    cor: work.cor,
    prazo: work.prazo,
    proximaConsulta: work.proximaConsulta,
    descricao: work.descricao,
  })
  const setField = <K extends keyof EditableWorkMetadata>(
    field: K,
    value: EditableWorkMetadata[K],
  ) => {
    setMetadata((previous) => ({ ...previous, [field]: value }))
  }

  return (
    <Modal
      title="Editar trabalho"
      subtitle={work.ref}
      onClose={onClose}
      width="max-w-2xl"
    >
      <div className="space-y-5 p-6">
        <div className="grid grid-cols-2 gap-4">
          <Input
            label="Identificação"
            value={metadata.identificadorPaciente}
            onChange={(value) => setField('identificadorPaciente', value)}
            placeholder="Ex: #PAC-8041"
            required
          />
          <Input
            label="Médico responsável"
            value={metadata.medico}
            onChange={(value) => setField('medico', value)}
            required
          />
          <Input
            label="Material"
            value={metadata.material}
            onChange={(value) => setField('material', value)}
          />
          <Input
            label="Cor"
            value={metadata.cor}
            onChange={(value) => setField('cor', value)}
            placeholder="Ex: A2"
          />
          <Input
            label="Prazo de entrega"
            type="date"
            value={metadata.prazo}
            onChange={(value) => setField('prazo', value)}
            required
          />
          <Input
            label="Próxima consulta"
            type="date"
            value={metadata.proximaConsulta}
            onChange={(value) => setField('proximaConsulta', value)}
          />
        </div>
        <Textarea
          label="Instruções clínicas"
          value={metadata.descricao}
          onChange={(value) => setField('descricao', value)}
          rows={4}
        />
        <div className="flex justify-end gap-2 border-t border-[var(--line)] pt-4">
          <Btn variant="ghost" onClick={onClose}>
            Cancelar
          </Btn>
          <Btn
            variant="primary"
            onClick={() => onSave(metadata)}
            disabled={
              !metadata.identificadorPaciente.trim() ||
              !metadata.medico.trim() ||
              !metadata.prazo
            }
          >
            Guardar alterações
          </Btn>
        </div>
      </div>
    </Modal>
  )
}
