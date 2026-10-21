import { useEffect, useState } from 'react'
import { ThemeProvider } from './theme'
import type { User, UserRole } from './data'
import Login from './views/Login'
import PublicLanding from './views/PublicLanding'
import Dashboard from './views/Dashboad'
import Trabalhos from './views/Trabalhos'
import Clientes from './views/Clientes'
import Colaboradores from './views/Colaboradores'
import Processos from './views/Processos'
import TiposTrabalho from './views/TiposTrabalho'
import Configuracoes from './views/Configuracoes'
import AuditLogs from './views/AuditLogs'
import TrabalhoDetalhe from './views/TrabalhoDetalhe'
import CollaboratorDashboard, { type CollaboratorView } from './views/CollaboratorDashboard'
import ClinicDesktopDashboard, { type ClinicDesktopView } from './views/ClinicDesktopDashboard'

type AdminSection = 'inicio' | 'trabalhos' | 'clientes' | 'colaboradores' | 'processos' | 'tipos' | 'configuracoes' | 'logs'

type AppRoute = '#/' | '#/entrar' | '#/admin' | '#/colaborador' | '#/clinica'

const ADMIN_NAV_ITEMS: { id: AdminSection; label: string; icon: string }[] = [
  { id: 'inicio', label: 'Dashboard', icon: '◫' },
  { id: 'trabalhos', label: 'Trabalhos', icon: '◧' },
  { id: 'clientes', label: 'Clientes', icon: '◎' },
  { id: 'colaboradores', label: 'Colaboradores', icon: '◑' },
  { id: 'processos', label: 'Processos', icon: '⬡' },
  { id: 'tipos', label: 'Tipos de Trabalho', icon: '◈' },
  { id: 'configuracoes', label: 'Configurações', icon: '⚙' },
  { id: 'logs', label: 'Logs', icon: '◌' },
]

function getCurrentHashRoute(): AppRoute {
  const hash = window.location.hash || '#/'
  if (hash === '#/entrar') return '#/entrar'
  if (hash.startsWith('#/admin')) return '#/admin'
  if (hash.startsWith('#/colaborador')) return '#/colaborador'
  if (hash.startsWith('#/clinica')) return '#/clinica'
  return '#/'
}

function getRoleRoute(role: UserRole): AppRoute {
  switch (role) {
    case 'admin':
      return '#/admin'
    case 'rececionista':
    case 'colaborador':
      return '#/colaborador'
    case 'clinica':
      return '#/clinica'
    default:
      return '#/'
  }
}

function DesktopAdminGuard({ onExit }: { onExit: () => void }) {
  return (
    <div className="min-h-screen bg-[#F3F4F6] flex items-center justify-center p-6">
      <div className="w-full max-w-lg bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-8 shadow-xl shadow-slate-900/5 text-center">
        <div className="mx-auto mb-5 flex h-14 w-14 items-center justify-center rounded-full border border-[#C9A227]/20 bg-[#C9A227]/10 text-2xl text-[#C9A227]">
          ◫
        </div>
        <p className="text-[10px] font-mono uppercase tracking-[0.2em] text-[#C9A227]">Desktop required</p>
        <h1 className="mt-3 text-[28px] font-serif text-[#1F2937]">Backoffice exclusivo em ecrã amplo</h1>
        <p className="mt-3 text-[13px] text-[#64748B] leading-relaxed">
          O painel administrativo do laboratório foi desenhado para desktop. Redimensione a janela para mais de 1024px para continuar.
        </p>
        <button
          type="button"
          onClick={onExit}
          className="mt-6 inline-flex items-center justify-center rounded-md bg-[#C9A227] px-4 py-2.5 text-[12px] font-semibold text-[#111827] hover:bg-[#D4AF37] transition-colors"
        >
          Voltar ao início
        </button>
      </div>
    </div>
  )
}

function AdminBackoffice({ user, onLogout }: { user: User; onLogout: () => void }) {
  const [activeSection, setActiveSection] = useState<AdminSection>('inicio')
  const [selectedWorkId, setSelectedWorkId] = useState<string | null>(null)
  const [viewportWidth, setViewportWidth] = useState<number>(() => window.innerWidth)

  useEffect(() => {
    const onResize = () => setViewportWidth(window.innerWidth)
    window.addEventListener('resize', onResize)
    return () => window.removeEventListener('resize', onResize)
  }, [])

  if (viewportWidth < 1024) {
    return <DesktopAdminGuard onExit={onLogout} />
  }

  if (selectedWorkId) {
    return (
      <TrabalhoDetalhe
        workId={selectedWorkId}
        onBack={() => setSelectedWorkId(null)}
        userRole={user.role}
      />
    )
  }

  return (
    <div className="flex h-screen min-h-screen bg-[#F3F4F6] text-[#1F2937]">
      <aside className="w-[250px] flex-shrink-0 border-r border-[#E5E7EB] bg-[#FFFFFF] flex flex-col">
        <div className="flex items-center gap-3 border-b border-[#E5E7EB] px-5 py-4">
          <div className="flex h-9 w-9 items-center justify-center rounded-sm bg-[#C9A227] text-base font-bold text-[#1F2937] font-serif">
            L
          </div>
          <div className="min-w-0">
            <p className="truncate text-[11px] font-semibold text-[#1F2937]">Laboratório Catarina Domingos</p>
            <p className="text-[9px] uppercase tracking-[0.18em] text-[#64748B]">Backoffice</p>
          </div>
        </div>

        <nav className="flex-1 space-y-1 p-3">
          {ADMIN_NAV_ITEMS.map(item => (
            <button
              key={item.id}
              type="button"
              onClick={() => setActiveSection(item.id)}
              className={`flex w-full items-center gap-3 rounded-sm px-3 py-2.5 text-left transition-colors ${
                activeSection === item.id
                  ? 'bg-[#C9A227]/10 text-[#C9A227] border border-[#C9A227]/15'
                  : 'text-[#475569] hover:bg-slate-100 hover:text-[#1F2937]'
              }`}
            >
              <span className="text-sm">{item.icon}</span>
              <span className="text-[13px] font-medium">{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="border-t border-[#E5E7EB] p-4">
          <div className="mb-3 flex items-center gap-3">
            <div className="flex h-9 w-9 items-center justify-center rounded-full bg-[#F3F4F6] text-[11px] font-medium text-[#1F2937]">
              {user.name.split(' ').map(part => part[0]).slice(0, 2).join('')}
            </div>
            <div className="min-w-0">
              <p className="truncate text-[12px] text-[#1F2937] font-medium">{user.name}</p>
              <p className="truncate text-[10px] text-[#64748B] uppercase">{user.role}</p>
            </div>
          </div>
          <button
            type="button"
            onClick={onLogout}
            className="w-full rounded-sm border border-[#E5E7EB] px-3 py-2 text-[12px] text-[#475569] hover:border-[#C9A227] hover:text-[#1F2937] transition-colors"
          >
            Sair
          </button>
        </div>
      </aside>

      <main className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <header className="flex items-center justify-between border-b border-[#E5E7EB] bg-[#FFFFFF] px-7 py-4">
          <div>
            <p className="text-[13px] font-medium text-[#1F2937]">
              {ADMIN_NAV_ITEMS.find(item => item.id === activeSection)?.label}
            </p>
            <p className="text-[11px] text-[#64748B]">Acesso administrativo</p>
          </div>
          <div className="text-[11px] text-[#64748B] font-mono">{new Date().toLocaleDateString('pt-PT')}</div>
        </header>

        {activeSection === 'inicio' && <Dashboard onSelectWork={id => setSelectedWorkId(id)} onNav={section => setActiveSection(section as AdminSection)} />}
        {activeSection === 'trabalhos' && <Trabalhos onSelectWork={id => setSelectedWorkId(id)} />}
        {activeSection === 'clientes' && <Clientes onSelectWork={id => setSelectedWorkId(id)} />}
        {activeSection === 'colaboradores' && <Colaboradores onSelectWork={id => setSelectedWorkId(id)} />}
        {activeSection === 'processos' && <Processos />}
        {activeSection === 'tipos' && <TiposTrabalho />}
        {activeSection === 'configuracoes' && <Configuracoes />}
        {activeSection === 'logs' && <AuditLogs />}
      </main>
    </div>
  )
}

function CollaboratorBackoffice({ user, onLogout }: { user: User; onLogout: () => void }) {
  const [activeView, setActiveView] = useState<CollaboratorView>('inicio')
  const [selectedWorkId, setSelectedWorkId] = useState<string | null>(null)

  if (selectedWorkId) {
    return (
      <TrabalhoDetalhe
        workId={selectedWorkId}
        onBack={() => setSelectedWorkId(null)}
        userRole={user.role}
        collaboratorView={activeView}
      />
    )
  }

  const navItems: { id: CollaboratorView; label: string; icon: string }[] = [
    { id: 'inicio', label: 'Início', icon: '◫' },
    { id: 'disponiveis', label: 'Disponíveis', icon: '◌' },
    { id: 'meus', label: 'Os meus', icon: '◑' },
    { id: 'prazos', label: 'Prazos', icon: '◎' },
  ]

  return (
    <div className="flex h-screen min-h-screen bg-[#F3F4F6] text-[#1F2937]">
      <aside className="w-[220px] flex-shrink-0 border-r border-[#E5E7EB] bg-[#FFFFFF] flex flex-col">
        <div className="border-b border-[#E5E7EB] px-5 py-4">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[#64748B]">Colaborador</p>
          <p className="mt-2 text-[16px] font-serif text-[#1F2937]">{user.name}</p>
        </div>

        <nav className="flex-1 space-y-1 p-3">
          {navItems.map(item => (
            <button
              key={item.id}
              type="button"
              onClick={() => setActiveView(item.id)}
              className={`flex w-full items-center gap-3 rounded-sm px-3 py-2.5 text-left transition-colors ${
                activeView === item.id ? 'bg-[#C9A227]/10 text-[#C9A227] border border-[#C9A227]/15' : 'text-[#475569] hover:bg-slate-100 hover:text-[#1F2937]'
              }`}
            >
              <span className="text-sm">{item.icon}</span>
              <span className="text-[13px] font-medium">{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="border-t border-[#E5E7EB] p-4">
          <button
            type="button"
            onClick={onLogout}
            className="w-full rounded-sm border border-[#E5E7EB] px-3 py-2 text-[12px] text-[#475569] hover:border-[#C9A227] hover:text-[#1F2937] transition-colors"
          >
            Sair
          </button>
        </div>
      </aside>

      <main className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <header className="flex items-center justify-between border-b border-[#E5E7EB] bg-[#FFFFFF] px-7 py-4">
          <div>
            <p className="text-[13px] font-medium text-[#1F2937]">Área de Produção</p>
            <p className="text-[11px] text-[#64748B]">{user.role === 'rececionista' ? 'Receção e gestão' : 'Execução de etapas'}</p>
          </div>
          <div className="text-[11px] text-[#64748B] font-mono">{new Date().toLocaleDateString('pt-PT')}</div>
        </header>

        <CollaboratorDashboard
          user={user}
          activeView={activeView}
          onViewChange={setActiveView}
          onSelectWork={id => setSelectedWorkId(id)}
        />
      </main>
    </div>
  )
}

function ClinicBackoffice({ user, onLogout }: { user: User; onLogout: () => void }) {
  const [activeView, setActiveView] = useState<ClinicDesktopView>('inicio')

  const navItems: { id: ClinicDesktopView; label: string; icon: string }[] = [
    { id: 'inicio', label: 'Início', icon: '◫' },
    { id: 'encomendas', label: 'Encomendas', icon: '◧' },
    { id: 'alertas', label: 'Alertas', icon: '⊠' },
    { id: 'conta', label: 'Conta', icon: '◑' },
  ]

  return (
    <div className="flex h-screen min-h-screen bg-[#F3F4F6] text-[#1F2937]">
      <aside className="w-[220px] flex-shrink-0 border-r border-[#E5E7EB] bg-[#FFFFFF] flex flex-col">
        <div className="border-b border-[#E5E7EB] px-5 py-4">
          <p className="text-[11px] uppercase tracking-[0.2em] text-[#64748B]">Clínica</p>
          <p className="mt-2 text-[16px] font-serif text-[#1F2937]">{user.name}</p>
        </div>

        <nav className="flex-1 space-y-1 p-3">
          {navItems.map(item => (
            <button
              key={item.id}
              type="button"
              onClick={() => setActiveView(item.id)}
              className={`flex w-full items-center gap-3 rounded-sm px-3 py-2.5 text-left transition-colors ${
                activeView === item.id ? 'bg-[#C9A227]/10 text-[#C9A227] border border-[#C9A227]/15' : 'text-[#475569] hover:bg-slate-100 hover:text-[#1F2937]'
              }`}
            >
              <span className="text-sm">{item.icon}</span>
              <span className="text-[13px] font-medium">{item.label}</span>
            </button>
          ))}
        </nav>

        <div className="border-t border-[#E5E7EB] p-4">
          <button
            type="button"
            onClick={onLogout}
            className="w-full rounded-sm border border-[#E5E7EB] px-3 py-2 text-[12px] text-[#475569] hover:border-[#C9A227] hover:text-[#1F2937] transition-colors"
          >
            Sair
          </button>
        </div>
      </aside>

      <main className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <header className="flex items-center justify-between border-b border-[#E5E7EB] bg-[#FFFFFF] px-7 py-4">
          <div>
            <p className="text-[13px] font-medium text-[#1F2937]">Portal da Clínica</p>
            <p className="text-[11px] text-[#64748B]">Acompanhamento de encomendas</p>
          </div>
          <div className="text-[11px] text-[#64748B] font-mono">{new Date().toLocaleDateString('pt-PT')}</div>
        </header>

        <ClinicDesktopDashboard user={user} activeView={activeView} onViewChange={setActiveView} />
      </main>
    </div>
  )
}

export default function App() {
  const [route, setRoute] = useState<AppRoute>(() => getCurrentHashRoute())
  const [user, setUser] = useState<User | null>(null)

  useEffect(() => {
    const onHashChange = () => setRoute(getCurrentHashRoute())
    window.addEventListener('hashchange', onHashChange)
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [])

  const navigate = (nextRoute: AppRoute) => {
    window.location.hash = nextRoute
    setRoute(nextRoute)
  }

  const handleLogin = (nextUser: User) => {
    setUser(nextUser)
    navigate(getRoleRoute(nextUser.role))
  }

  const handleLogout = () => {
    setUser(null)
    navigate('#/')
  }

  return (
    <ThemeProvider>
      {route === '#/entrar' ? (
        <Login onLogin={handleLogin} onBack={() => navigate('#/')} />
      ) : route === '#/' ? (
        <PublicLanding onPortal={() => navigate('#/entrar')} />
      ) : user && route === '#/admin' ? (
        <AdminBackoffice user={user} onLogout={handleLogout} />
      ) : user && route === '#/colaborador' ? (
        <CollaboratorBackoffice user={user} onLogout={handleLogout} />
      ) : user && route === '#/clinica' ? (
        <ClinicBackoffice user={user} onLogout={handleLogout} />
      ) : (
        <PublicLanding onPortal={() => navigate('#/entrar')} />
      )}
    </ThemeProvider>
  )
}