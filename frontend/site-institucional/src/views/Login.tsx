import { useState, type FormEvent } from 'react'
import type { User } from '../data'
import { COLABORADORES } from '../data'
import { ThemeToggle } from '../theme'

const DEMO_USERS = [
  { email: 'catarina@lcd.pt', password: 'admin', role: 'admin' as const, name: 'Catarina Domingos' },
  { email: 'marta@lcd.pt', password: 'rececionista', role: 'rececionista' as const, name: 'Marta Oliveira' },
  { email: 'ana@lcd.pt', password: 'colaborador', role: 'colaborador' as const, name: 'Ana Martins' },
  { email: 'geral@horizonte.pt', password: 'clinica', role: 'clinica' as const, name: 'Clínica Dental Horizonte' },
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

  const handleSubmit = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    setTimeout(() => {
      const match = DEMO_USERS.find(u => u.email === email && u.password === password)
      if (match) {
        const colab = COLABORADORES.find(c => c.email === email)
        onLogin({ id: colab?.id ?? 'u0', name: match.name, email: match.email, role: match.role })
      } else {
        setError('Credenciais inválidas. Verifique o e-mail e a palavra-passe.')
      }
      setLoading(false)
    }, 800)
  }

  const handleForgot = (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    setForgotSent(true)
  }

  if (showForgot) {
    return (
      <div className="min-h-screen bg-[#F3F4F6] flex items-center justify-center p-4">
        <div className="w-full max-w-sm">
          <div className="flex justify-center mb-10">
            <LabLogo />
          </div>
          <div className="bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm p-8">
            {forgotSent ? (
              <div className="text-center space-y-4">
                <div className="w-10 h-10 rounded-full bg-emerald-400/10 border border-emerald-400/30 flex items-center justify-center mx-auto">
                  <span className="text-emerald-700">✓</span>
                </div>
                <h2 className="text-[14px] font-serif text-[#1F2937]">E-mail enviado</h2>
                <p className="text-[12px] text-[#475569]">Verifique a sua caixa de entrada para instruções de recuperação de acesso.</p>
                <button onClick={() => { setShowForgot(false); setForgotSent(false) }} className="text-[12px] text-[#C9A227] hover:text-[#D4AF37] transition-colors">← Voltar ao início de sessão</button>
              </div>
            ) : (
              <>
                <h2 className="text-[15px] font-serif text-[#1F2937] mb-1">Recuperar acesso</h2>
                <p className="text-[12px] text-[#475569] mb-6">Introduza o seu e-mail para receber instruções de recuperação.</p>
                <form onSubmit={handleForgot} className="space-y-4">
                  <div className="space-y-1">
                    <label className="text-[10px] font-mono text-[#6B7280] uppercase tracking-wider">E-mail</label>
                    <input type="email" required placeholder="nome@laboratorio.pt"
                      className="w-full px-3 py-2.5 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none" />
                  </div>
                  <button type="submit" className="w-full py-2.5 bg-[#C9A227] text-[#1F2937] text-[13px] font-semibold rounded-sm hover:bg-[#D4AF37] transition-colors">Enviar instruções</button>
                </form>
                <button onClick={() => setShowForgot(false)} className="mt-4 text-[11px] text-[#64748B] hover:text-[#C9A227] transition-colors">← Voltar ao início de sessão</button>
              </>
            )}
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#F3F4F6] flex items-center justify-center p-5 relative">
      <div className="fixed top-5 left-5">
        <button onClick={onBack} className="text-[11px] text-[#64748B] hover:text-[#C9A227]">← Voltar ao website</button>
      </div>
      <div className="fixed top-5 right-5"><ThemeToggle /></div>

      <div className="w-full max-w-md bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-7 md:p-8 shadow-xl shadow-slate-900/5">
        <div className="flex justify-center mb-7"><LabLogo /></div>
        <div className="text-center mb-7">
          <p className="text-[10px] font-semibold text-[#C9A227] uppercase tracking-[0.16em]">Portal reservado</p>
          <h1 className="text-[24px] font-serif font-semibold text-[#1F2937] mt-2">Iniciar sessão</h1>
          <p className="text-[12px] text-[#64748B] mt-1">Acesso para laboratório, colaboradores e clínicas.</p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-2">
              <label className="text-[11px] font-medium text-[#374151]">E-mail ou utilizador</label>
              <input
                type="email" value={email} onChange={e => setEmail(e.target.value)} required
                placeholder="nome@laboratorio.pt" autoComplete="username"
                className="w-full px-4 py-3 bg-[#FFFFFF] border border-[#D1D5DB] rounded-md text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227] focus:ring-2 focus:ring-[#C9A227]/10 focus:outline-none transition-all"
              />
            </div>

            <div className="space-y-2">
              <label className="text-[11px] font-medium text-[#374151]">Palavra-passe</label>
              <input
                type="password" value={password} onChange={e => setPassword(e.target.value)} required
                placeholder="••••••••" autoComplete="current-password"
                className="w-full px-4 py-3 bg-[#FFFFFF] border border-[#D1D5DB] rounded-md text-[13px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227] focus:ring-2 focus:ring-[#C9A227]/10 focus:outline-none transition-all"
              />
            </div>

            {error && (
              <div className="flex items-center gap-2 px-3 py-2.5 bg-red-500/8 border border-red-500/25 rounded-sm">
                <span className="text-red-700 text-xs">✕</span>
                <p className="text-[12px] text-red-700">{error}</p>
              </div>
            )}

            <button type="submit" disabled={loading}
              className="w-full py-3 bg-[#C9A227] text-[#111827] text-[13px] font-bold rounded-md hover:bg-[#D4AF37] disabled:opacity-50 transition-colors flex items-center justify-center gap-2 shadow-sm">
              {loading ? <><span className="animate-spin text-base">◷</span> A verificar...</> : 'Entrar'}
            </button>

            <button type="button" onClick={() => setShowForgot(true)} className="w-full text-center text-[12px] font-medium text-[#64748B] hover:text-[#1F2937] transition-colors">
              Esqueci-me da palavra-passe
            </button>
        </form>

        {onSwitchApp && (
          <button onClick={onSwitchApp} className="mt-5 w-full py-2.5 border border-[#D1D5DB] rounded-md text-[11px] font-medium text-[#475569] hover:border-[#C9A227]">
            Abrir App Clínicas / Colaboradores
          </button>
        )}

        <div className="mt-5 pt-5 border-t border-[#E5E7EB]">
          <p className="text-[9px] font-semibold text-[#6B7280] uppercase tracking-wider mb-2">Acesso de demonstração</p>
          <div className="grid grid-cols-2 gap-1">
            {DEMO_USERS.map(u => (
              <button key={u.email} onClick={() => { setEmail(u.email); setPassword(u.password) }}
                className="truncate text-left text-[9px] font-mono text-[#64748B] hover:text-[#C9A227] py-1">
                {u.role === 'admin' ? '★' : u.role === 'rececionista' ? '◎' : u.role === 'clinica' ? '◇' : '◑'} {u.role}
              </button>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}

function LabLogo({ horizontal }: { horizontal?: boolean }) {
  if (horizontal) {
    return (
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 bg-[#C9A227] rounded-sm flex items-center justify-center">
          <span className="text-[#1F2937] font-bold text-base font-serif">L</span>
        </div>
        <div>
          <p className="text-[13px] font-semibold text-white tracking-wide">Laboratório Catarina Domingos</p>
          <p className="text-[10px] text-[#737373] tracking-widest uppercase">Prótese Dentária</p>
        </div>
      </div>
    )
  }
  return (
    <div className="flex flex-col items-center gap-3">
      <div className="w-12 h-12 bg-[#C9A227] rounded-sm flex items-center justify-center">
        <span className="text-[#1F2937] font-bold text-xl font-serif">L</span>
      </div>
      <div className="text-center">
        <p className="text-[13px] font-semibold text-[#1F2937]">Catarina Domingos</p>
        <p className="text-[10px] text-[#64748B] tracking-widest uppercase">Laboratório de Prótese Dentária</p>
      </div>
    </div>
  )
}
