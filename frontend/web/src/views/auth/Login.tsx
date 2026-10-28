import BrandLogo from '../../components/BrandLogo'
import { useState } from 'react'
import type { User } from '../../data'
import { COLABORADORES, CLIENTES } from '../../data'
import '../../mockWorkStore'

import { ThemeToggle } from '../../theme'

const DEMO_USERS = [
  {
    email: 'catarina@lcd.pt',
    password: 'admin',
    role: 'admin' as const,
    label: 'Admin',
    name: 'Catarina Domingos',
  },
  {
    email: 'marta@lcd.pt',
    password: 'colaborador',
    role: 'colaborador' as const,
    label: 'Marta',
    name: 'Marta Oliveira',
  },
  {
    email: 'ana@lcd.pt',
    password: 'colaborador',
    role: 'colaborador' as const,
    label: 'Colaborador',
    name: 'Ana Martins',
  },
  {
    email: 'geral@horizonte.pt',
    password: 'clinica',
    role: 'clinica' as const,
    label: 'Clínica',
    name: 'Clínica Dental Horizonte',
  },
]

interface LoginProps {
  onLogin: (user: User) => void
  onBack: () => void
  onSwitchApp?: () => void
}

export default function Login({ onLogin, onBack, onSwitchApp }: LoginProps) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [showForgot, setShowForgot] = useState(false)
  const [forgotSent, setForgotSent] = useState(false)

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    setTimeout(() => {
      const identifier = email.trim().toLowerCase()
      const alias = DEMO_USERS.find(
        (u) => u.role === identifier || u.label.toLowerCase() === identifier,
      )
      const loginEmail = alias?.email ?? identifier
      const clinic = CLIENTES.find((c) => c.email.toLowerCase() === loginEmail)
      const colab = COLABORADORES.find(
        (c) => c.email.toLowerCase() === loginEmail,
      )
      if (clinic && password === 'clinica') {
        if (clinic.status !== 'ativo')
          setError(
            clinic.status === 'suspenso'
              ? 'Conta suspensa. Contacte o laboratório.'
              : 'Conta a aguardar aprovação.',
          )
        else
          onLogin({
            id: clinic.id,
            name: clinic.name,
            email: clinic.email,
            role: 'clinica',
          })
      } else if (colab && !colab.deletedAt && password === colab.role) {
        onLogin({
          id: colab.id,
          name: colab.name,
          email: colab.email,
          role: colab.role,
        })
      } else {
        setError('Credenciais inválidas. Verifique o e-mail e a palavra-passe.')
      }
      setLoading(false)
    }, 800)
  }

  const handleForgot = (e: React.FormEvent) => {
    e.preventDefault()
    setForgotSent(true)
  }

  if (showForgot) {
    return (
      <div className="min-h-screen bg-[var(--paper)] text-[var(--ink)] flex items-center justify-center p-4">
        <div className="w-full max-w-sm">
          <div className="flex justify-center mb-10">
            <BrandLogo width={155} />
          </div>
          <div className="bg-[var(--surface)] border border-[var(--line)] rounded-lg p-8 shadow-[var(--shadow)]">
            {forgotSent ? (
              <div className="text-center space-y-4">
                <div className="w-10 h-10 rounded-full bg-[var(--badge-success-bg)] border border-[var(--badge-success-text)] flex items-center justify-center mx-auto">
                  <span className="text-[var(--badge-success-text)]">✓</span>
                </div>
                <h2 className="text-[14px] font-serif text-[var(--ink)]">
                  E-mail enviado
                </h2>
                <p className="text-[12px] text-[var(--muted)]">
                  Verifique a sua caixa de entrada para instruções de
                  recuperação de acesso.
                </p>
                <button
                  onClick={() => {
                    setShowForgot(false)
                    setForgotSent(false)
                  }}
                  className="text-[12px] text-[var(--gold-ink)] hover:opacity-80"
                >
                  ← Voltar ao início de sessão
                </button>
              </div>
            ) : (
              <>
                <h2 className="text-[15px] font-serif text-[var(--ink)] mb-1">
                  Recuperar acesso
                </h2>
                <p className="text-[12px] text-[var(--muted)] mb-6">
                  Introduza o seu e-mail para receber instruções de recuperação.
                </p>
                <form onSubmit={handleForgot} className="space-y-4">
                  <div className="space-y-1">
                    <label className="text-[10px] font-mono text-[var(--muted)] uppercase tracking-wider">
                      E-mail
                    </label>
                    <input
                      type="email"
                      required
                      placeholder="nome@laboratorio.pt"
                      className="w-full px-3 py-2.5 bg-[var(--surface)] border border-[var(--input-line)] rounded-[5px] text-[13px] text-[var(--ink)] placeholder:text-[var(--muted)] focus:border-[var(--gold)] focus:outline-none focus:ring-2 focus:ring-[var(--gold)]"
                    />
                  </div>
                  <button
                    type="submit"
                    className="w-full py-2.5 bg-[var(--gold)] text-[#181B20] text-[13px] font-semibold rounded-[5px] hover:opacity-90"
                  >
                    Enviar instruções
                  </button>
                </form>
                <button
                  onClick={() => setShowForgot(false)}
                  className="mt-4 text-[11px] text-[var(--muted)] hover:text-[var(--gold-ink)]"
                >
                  ← Voltar ao início de sessão
                </button>
              </>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[var(--paper)] text-[var(--ink)] flex items-center justify-center px-5 py-20 relative">
      <div className="fixed top-5 left-5">
        <button
          onClick={onBack}
          className="text-[11px] text-[var(--muted)] hover:text-[var(--gold-ink)]"
        >
          ← Voltar ao website
        </button>
      </div>
      <div className="fixed top-5 right-5">
        <ThemeToggle />
      </div>

      <div className="login-card w-full">
        <div className="flex justify-center mb-7">
          <BrandLogo width={155} />
        </div>
        <div className="text-center mb-7">
          <p className="text-[10px] font-semibold text-[var(--gold-ink)] uppercase tracking-[0.16em]">
            Laboratório de Prótese Dentária
          </p>
          <h1 className="text-[27px] font-medium text-[var(--ink)] mt-2">
            Bem-vindo
          </h1>
          <p className="text-[12px] text-[var(--muted)] mt-1"></p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <label className="text-[11px] font-medium text-[var(--ink)]">
              E-mail
            </label>
            <input
              type="text"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              placeholder="nome@laboratorio.pt"
              autoComplete="username"
              className="w-full min-h-11 px-4 py-3 bg-[var(--surface)] border border-[var(--input-line)] rounded-[5px] text-[13px] text-[var(--ink)] placeholder:text-[var(--muted)] focus:border-[var(--gold)] focus:outline-none focus:ring-2 focus:ring-[var(--gold)] focus:ring-offset-2"
            />
          </div>

          <div className="space-y-2">
            <label className="text-[11px] font-medium text-[var(--ink)]">
              Palavra-passe
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              placeholder="••••••••"
              autoComplete="current-password"
              className="w-full min-h-11 px-4 py-3 bg-[var(--surface)] border border-[var(--input-line)] rounded-[5px] text-[13px] text-[var(--ink)] placeholder:text-[var(--muted)] focus:border-[var(--gold)] focus:outline-none focus:ring-2 focus:ring-[var(--gold)] focus:ring-offset-2"
            />
          </div>

          {error && (
            <div className="flex items-center gap-2 px-3 py-2.5 bg-[var(--badge-standby-bg)] border border-[var(--badge-standby-text)] rounded-[5px]">
              <span className="text-[var(--badge-standby-text)] text-xs">
                ✕
              </span>
              <p className="text-[12px] text-[var(--badge-standby-text)]">
                {error}
              </p>
            </div>
          )}

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-[var(--gold)] text-[#181B20] text-[13px] font-bold rounded-[5px] hover:opacity-90 disabled:opacity-50 flex items-center justify-center gap-2 shadow-sm"
          >
            {loading ? (
              <>
                <span className="animate-spin text-base">◷</span> A verificar...
              </>
            ) : (
              'Entrar'
            )}
          </button>

          <button
            type="button"
            onClick={() => setShowForgot(true)}
            className="w-full text-center text-[12px] font-medium text-[var(--muted)] hover:text-[var(--ink)]"
          >
            Esqueci-me da palavra-passe
          </button>
        </form>

        {onSwitchApp && (
          <button
            onClick={onSwitchApp}
            className="mt-5 w-full py-2 text-center text-[12px] text-[var(--muted)] hover:text-[var(--gold-ink)] transition-colors"
          >
            Aceder à aplicação móvel →
          </button>
        )}
      </div>
    </div>
  )
}
