import { useState } from 'react'
import {
  SectionTitle,
  Input,
  Textarea,
  Toggle,
  Btn,
  GoldDivider,
  useToast,
} from '../../components/ui'

type SettingsSection = 'conta' | 'laboratorio' | 'notificacoes' | 'seguranca'

export default function Configuracoes() {
  const [section, setSection] = useState<SettingsSection>('laboratorio')
  const { show, ToastEl } = useToast()

  const sections: { id: SettingsSection; label: string; icon: string }[] = [
    { id: 'laboratorio', label: 'Laboratório', icon: '◎' },
    { id: 'conta', label: 'Conta', icon: '◑' },
    { id: 'notificacoes', label: 'Notificações', icon: '⊠' },
    { id: 'seguranca', label: 'Segurança', icon: '⊟' },
  ]

  return (
    <div className="flex-1 flex overflow-hidden">
      {ToastEl}

      {/* Sidebar */}
      <div className="w-52 flex-shrink-0 border-r border-[#E5E7EB] py-4 px-2">
        {sections.map((s) => (
          <button
            key={s.id}
            onClick={() => setSection(s.id)}
            className={`w-full flex items-center gap-2.5 px-3 py-2.5 rounded-sm text-left transition-colors ${section === s.id ? 'bg-[#C9A227]/10 text-[#C9A227]' : 'text-[#475569] hover:text-[#1F2937] hover:bg-slate-100'}`}
          >
            <span className="text-sm">{s.icon}</span>
            <span className="text-[13px] font-medium">{s.label}</span>
          </button>
        ))}
      </div>

      {/* Content */}
      <div className="flex-1 overflow-y-auto p-8">
        {section === 'laboratorio' && (
          <LabSettings onSave={() => show('Configurações guardadas')} />
        )}
        {section === 'conta' && (
          <ContaSettings onSave={() => show('Conta atualizada')} />
        )}
        {section === 'notificacoes' && (
          <NotifSettings onSave={() => show('Preferências guardadas')} />
        )}
        {section === 'seguranca' && (
          <SegurancaSettings onSave={() => show('Palavra-passe alterada')} />
        )}
      </div>
    </div>
  )
}

function LabSettings({ onSave }: { onSave: () => void }) {
  const [name, setName] = useState('Laboratório Catarina Domingos')
  const [nif, setNif] = useState('PT 512 345 678')
  const [address, setAddress] = useState('Rua das Anémonas 42, 4100-050 Porto')
  const [phone, setPhone] = useState('+351 226 000 111')
  const [email, setEmail] = useState('geral@lcd.pt')
  const [desc, setDesc] = useState(
    'Laboratório de prótese dentária especializado em prótese fixa, removível e trabalhos digitais CAD/CAM.',
  )

  return (
    <div className="max-w-xl space-y-6">
      <div>
        <h2 className="text-[18px] font-serif text-[#1F2937]">
          Informação do Laboratório
        </h2>
        <p className="text-[12px] text-[#64748B] mt-1">
          Dados institucionais e de contacto
        </p>
      </div>
      <GoldDivider />
      <div className="space-y-4">
        <Input
          label="Nome do laboratório"
          value={name}
          onChange={setName}
          required
        />
        <Input label="NIF" value={nif} onChange={setNif} />
        <Input label="Endereço" value={address} onChange={setAddress} />
        <div className="grid grid-cols-2 gap-4">
          <Input label="Telefone" value={phone} onChange={setPhone} />
          <Input
            label="E-mail geral"
            value={email}
            onChange={setEmail}
            type="email"
          />
        </div>
        <Textarea
          label="Descrição / Apresentação"
          value={desc}
          onChange={setDesc}
          rows={3}
        />
      </div>
      <div className="pt-2">
        <Btn variant="primary" onClick={onSave}>
          Guardar alterações
        </Btn>
      </div>
    </div>
  )
}

function ContaSettings({ onSave }: { onSave: () => void }) {
  const [name, setName] = useState('Catarina Domingos')
  const [email, setEmail] = useState('catarina@lcd.pt')

  return (
    <div className="max-w-xl space-y-6">
      <div>
        <h2 className="text-[18px] font-serif text-[#1F2937]">A minha conta</h2>
        <p className="text-[12px] text-[#64748B] mt-1">
          Informações pessoais e preferências
        </p>
      </div>
      <GoldDivider />
      <div className="space-y-4">
        <Input label="Nome" value={name} onChange={setName} required />
        <Input
          label="E-mail"
          value={email}
          onChange={setEmail}
          type="email"
          required
        />
      </div>
      <div className="pt-2">
        <Btn variant="primary" onClick={onSave}>
          Guardar
        </Btn>
      </div>
    </div>
  )
}

function NotifSettings({ onSave }: { onSave: () => void }) {
  const [prefs, setPrefs] = useState({
    prazoUrgente: true,
    novoTrabalho: true,
    etapaConcluida: false,
    standby: true,
    concluido: true,
    email: true,
    browser: false,
  })

  const toggle = (key: keyof typeof prefs) =>
    setPrefs((prev) => ({ ...prev, [key]: !prev[key] }))

  return (
    <div className="max-w-xl space-y-6">
      <div>
        <h2 className="text-[18px] font-serif text-[#1F2937]">Notificações</h2>
        <p className="text-[12px] text-[#64748B] mt-1">
          Controle os alertas que recebe
        </p>
      </div>
      <GoldDivider />

      <div className="space-y-4">
        <SectionTitle>Eventos</SectionTitle>
        {[
          {
            key: 'prazoUrgente',
            label: 'Prazos urgentes',
            desc: 'Trabalhos a 2 dias ou menos do prazo',
          },
          {
            key: 'novoTrabalho',
            label: 'Novo trabalho recebido',
            desc: 'Quando uma clínica submete um trabalho',
          },
          {
            key: 'etapaConcluida',
            label: 'Etapa concluída',
            desc: 'Quando um colaborador conclui uma etapa',
          },
          {
            key: 'standby',
            label: 'Trabalho em standby',
            desc: 'Quando um trabalho é colocado em espera',
          },
          {
            key: 'concluido',
            label: 'Trabalho concluído',
            desc: 'Quando um trabalho é finalizado',
          },
        ].map((item) => (
          <div
            key={item.key}
            className="flex items-center justify-between py-2"
          >
            <div>
              <p className="text-[13px] text-[#1F2937]">{item.label}</p>
              <p className="text-[11px] text-[#64748B] mt-0.5">{item.desc}</p>
            </div>
            <Toggle
              checked={prefs[item.key as keyof typeof prefs] as boolean}
              onChange={() => toggle(item.key as keyof typeof prefs)}
            />
          </div>
        ))}
      </div>

      <GoldDivider />

      <div className="space-y-4">
        <SectionTitle>Canais</SectionTitle>
        {[
          {
            key: 'email',
            label: 'E-mail',
            desc: 'Receber notificações por e-mail',
          },
          {
            key: 'browser',
            label: 'Navegador',
            desc: 'Notificações push no browser',
          },
        ].map((item) => (
          <div
            key={item.key}
            className="flex items-center justify-between py-2"
          >
            <div>
              <p className="text-[13px] text-[#1F2937]">{item.label}</p>
              <p className="text-[11px] text-[#64748B] mt-0.5">{item.desc}</p>
            </div>
            <Toggle
              checked={prefs[item.key as keyof typeof prefs] as boolean}
              onChange={() => toggle(item.key as keyof typeof prefs)}
            />
          </div>
        ))}
      </div>

      <div className="pt-2">
        <Btn variant="primary" onClick={onSave}>
          Guardar preferências
        </Btn>
      </div>
    </div>
  )
}

function SegurancaSettings({ onSave }: { onSave: () => void }) {
  const [current, setCurrent] = useState('')
  const [next, setNext] = useState('')
  const [confirm, setConfirm] = useState('')
  const [error, setError] = useState('')

  const handleSave = () => {
    if (!current || !next || !confirm) {
      setError('Preencha todos os campos.')
      return
    }
    if (next !== confirm) {
      setError('As palavras-passe não coincidem.')
      return
    }
    if (next.length < 8) {
      setError('A palavra-passe deve ter pelo menos 8 caracteres.')
      return
    }
    setError('')
    setCurrent('')
    setNext('')
    setConfirm('')
    onSave()
  }

  return (
    <div className="max-w-md space-y-6">
      <div>
        <h2 className="text-[18px] font-serif text-[#1F2937]">Segurança</h2>
        <p className="text-[12px] text-[#64748B] mt-1">
          Altere a palavra-passe da sua conta
        </p>
      </div>
      <GoldDivider />
      <div className="space-y-4">
        <Input
          label="Palavra-passe atual"
          value={current}
          onChange={setCurrent}
          type="password"
          required
        />
        <Input
          label="Nova palavra-passe"
          value={next}
          onChange={setNext}
          type="password"
          required
        />
        <Input
          label="Confirmar nova palavra-passe"
          value={confirm}
          onChange={setConfirm}
          type="password"
          required
        />
        {error && (
          <p className="text-[12px] text-red-700 flex items-center gap-1">
            <span>!</span> {error}
          </p>
        )}
      </div>
      <div>
        <Btn variant="primary" onClick={handleSave}>
          Alterar palavra-passe
        </Btn>
      </div>

      <GoldDivider />
      <div>
        <SectionTitle>Sessões ativas</SectionTitle>
        <div className="space-y-2">
          {[
            {
              device: 'Chrome · macOS',
              location: 'Porto, Portugal',
              current: true,
            },
            {
              device: 'Safari · iPhone',
              location: 'Porto, Portugal',
              current: false,
            },
          ].map((s, i) => (
            <div
              key={i}
              className="flex items-center gap-3 px-4 py-3 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm"
            >
              <span className="text-[#64748B] text-sm">◑</span>
              <div className="flex-1">
                <p className="text-[12px] text-[#1F2937]">{s.device}</p>
                <p className="text-[11px] text-[#64748B]">{s.location}</p>
              </div>
              {s.current ? (
                <span className="text-[10px] font-mono text-emerald-700 border border-emerald-400/25 px-2 py-0.5 rounded-sm">
                  Atual
                </span>
              ) : (
                <button className="text-[11px] text-red-700 hover:text-red-300 transition-colors">
                  Terminar
                </button>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
