import BrandLogo from './components/BrandLogo'
import DesktopNotifications from './components/DesktopNotifications'
import { useState, useEffect } from 'react'
import type { User, UserRole } from './data'
import { Avatar, RoleBadge } from './components/ui'
import Login from './views/auth/Login'
import Dashboard from './views/backoffice/Dashboard'
import Trabalhos from './views/backoffice/Trabalhos'
import TrabalhoDetalhe from './views/backoffice/TrabalhoDetalhe'
import Clientes from './views/backoffice/Clientes'
import Colaboradores from './views/backoffice/Colaboradores'
import Processos from './views/backoffice/Processos'
import TiposTrabalho from './views/backoffice/TiposTrabalho'
import Configuracoes from './views/backoffice/Configuracoes'
import AuditLogs from './views/backoffice/AuditLogs'
import CollaboratorDashboard, {
  type CollaboratorView,
} from './views/backoffice/CollaboratorDashboard'
import ClinicDesktopDashboard, {
  type ClinicDesktopView,
} from './views/backoffice/ClinicDesktopDashboard'
import PublicLanding from './views/institucional/PublicLanding'
import { ThemeToggle } from './theme'
import { useMockWorkState } from './mockWorkStore'
import { AppIcon, type IconName } from './components/icons'

// ─── Nav config ───────────────────────────────────────────────────────────────

type NavSection =
  | 'dashboard'
  | 'trabalhos'
  | 'clientes'
  | 'colaboradores'
  | 'processos'
  | 'tipos'
  | 'configuracoes'
  | 'atividades'
type AppSection = NavSection | CollaboratorView | ClinicDesktopView

interface NavItem {
  id: AppSection
  label: string
  icon: IconName
  roles: UserRole[]
  count?: number
  group?: string
}

const NAV_ITEMS: NavItem[] = [
  {
    id: 'dashboard',
    label: 'Dashboard',
    icon: 'layout',
    roles: ['admin', 'colaborador'],
  },
  {
    id: 'trabalhos',
    label: 'Trabalhos',
    icon: 'clipboard',
    roles: ['admin', 'colaborador'],
    count: 8,
    group: 'operacional',
  },
  {
    id: 'clientes',
    label: 'Clientes',
    icon: 'building',
    roles: ['admin'],
    group: 'operacional',
  },
  {
    id: 'colaboradores',
    label: 'Colaboradores',
    icon: 'users',
    roles: ['admin'],
    group: 'operacional',
  },
  {
    id: 'atividades',
    label: 'Registo de Atividades',
    icon: 'list',
    roles: ['admin'],
    group: 'operacional',
  },
  {
    id: 'tipos',
    label: 'Tipos de Trabalho',
    icon: 'layers',
    roles: ['admin'],
    group: 'configuracao',
  },
  {
    id: 'processos',
    label: 'Etapas de Produção',
    icon: 'workflow',
    roles: ['admin'],
    group: 'configuracao',
  },
  {
    id: 'configuracoes',
    label: 'Configurações',
    icon: 'settings',
    roles: ['admin'],
    group: 'configuracao',
  },
]

const COLLABORATOR_NAV_ITEMS: NavItem[] = [
  { id: 'inicio', label: 'Início', icon: 'layout', roles: ['colaborador'] },
  {
    id: 'disponiveis',
    label: 'Trabalhos Disponíveis',
    icon: 'clipboard',
    roles: ['colaborador'],
  },
  {
    id: 'meus',
    label: 'Os Meus Trabalhos',
    icon: 'package',
    roles: ['colaborador'],
  },
  { id: 'prazos', label: 'Prazos', icon: 'alert', roles: ['colaborador'] },
]

const CLINIC_NAV_ITEMS: NavItem[] = [
  { id: 'inicio', label: 'Início', icon: 'layout', roles: ['clinica'] },
  {
    id: 'encomendas',
    label: 'Encomendas',
    icon: 'package',
    roles: ['clinica'],
  },
  { id: 'alertas', label: 'Alertas', icon: 'bell', roles: ['clinica'] },
  { id: 'conta', label: 'Conta', icon: 'user', roles: ['clinica'] },
]

const PAGE_TITLES: Record<NavSection, { title: string; subtitle: string }> = {
  dashboard: { title: 'Dashboard', subtitle: 'Visão geral do laboratório' },
  trabalhos: { title: 'Trabalhos', subtitle: 'Gestão de ordens de trabalho' },
  clientes: { title: 'Clientes', subtitle: 'Clínicas e consultórios' },
  colaboradores: { title: 'Colaboradores', subtitle: 'Equipa e permissões' },
  processos: {
    title: 'Processos',
    subtitle: 'Configuração de fluxos de produção',
  },
  tipos: { title: 'Tipos de Trabalho', subtitle: 'Categorias e configuração' },
  configuracoes: { title: 'Configurações', subtitle: 'Definições do sistema' },
  atividades: {
    title: 'Registo de Atividades',
    subtitle: 'Auditoria de ações e alterações',
  },
}

// ─── Responsive hook ──────────────────────────────────────────────────────────

function useWindowWidth() {
  const [width, setWidth] = useState(() => window.innerWidth)
  useEffect(() => {
    const handler = () => setWidth(window.innerWidth)
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])
  return width
}

function useMediaQuery(query: string) {
  const [matches, setMatches] = useState(() => window.matchMedia(query).matches)
  useEffect(() => {
    const mediaQuery = window.matchMedia(query)
    const handler = (event: MediaQueryListEvent) => setMatches(event.matches)
    setMatches(mediaQuery.matches)
    mediaQuery.addEventListener('change', handler)
    return () => mediaQuery.removeEventListener('change', handler)
  }, [query])
  return matches
}

// ─── Sidebar ──────────────────────────────────────────────────────────────────

interface SidebarProps {
  user: User
  active: AppSection
  onNav: (s: AppSection) => void
  onLogout: () => void
  collapsed: boolean
  onClose?: () => void
}

function Sidebar({
  user,
  active,
  onNav,
  collapsed,
  onClose,
  onLogout,
}: SidebarProps) {
  const isCollaborator = user.role === 'colaborador'
  const isClinic = user.role === 'clinica'
  const visibleItems = isCollaborator
    ? COLLABORATOR_NAV_ITEMS
    : isClinic
      ? CLINIC_NAV_ITEMS
      : NAV_ITEMS.filter((item) => item.roles.includes(user.role))
  const operacional = visibleItems.filter(
    (i) => i.id !== 'dashboard' && i.group === 'operacional',
  )
  const configuracao = visibleItems.filter((i) => i.group === 'configuracao')

  const NavBtn = ({ item }: { item: NavItem }) => {
    const isActive = active === item.id
    const handleClick = () => {
      onNav(item.id)
      onClose?.()
    }
    if (collapsed) {
      return (
        <button
          onClick={handleClick}
          title={item.label}
          className={`relative w-full flex items-center justify-center p-3 rounded-md transition-all border ${
            isActive
              ? 'bg-[#C9A227] text-[#1F2937] border-[#C9A227] shadow-sm'
              : 'text-white/85 hover:text-white hover:bg-white/8 border-transparent'
          }`}
        >
          <AppIcon
            name={item.icon}
            className={`h-4 w-4 ${
              isActive ? 'text-[#121417]' : 'text-white/70'
            }`}
          />
          {item.count !== undefined && isActive && (
            <span className="absolute top-1 right-1 w-1.5 h-1.5 bg-[#C9A227] rounded-full" />
          )}
        </button>
      )
    }
    return (
      <button
        onClick={handleClick}
        className={`relative w-full flex items-center justify-between px-4 py-2.5 rounded-md text-left transition-all border ${
          isActive
            ? 'bg-[#C9A227] text-[#1F2937] border-[#C9A227] shadow-sm'
            : 'text-white/85 hover:text-white hover:bg-white/8 border-transparent'
        }`}
      >
        <span className="flex items-center gap-2.5">
          <AppIcon
            name={item.icon}
            className={`h-4 w-4 ${
              isActive ? 'text-[#121417]' : 'text-white/70'
            }`}
          />
          <span className="text-[13px] font-medium">{item.label}</span>
        </span>
        {item.count !== undefined && (
          <span
            className={`text-[10px] font-mono px-1.5 py-0.5 rounded-sm ${
              isActive
                ? 'bg-black/10 text-[#121417]'
                : 'bg-white/10 text-white/85'
            }`}
          >
            {item.count}
          </span>
        )}
      </button>
    )
  }

  return (
    <aside
      className={`flex-shrink-0 flex flex-col border-r border-white/10 bg-[var(--obsidian)] transition-all duration-200 ${
        collapsed ? 'w-16' : 'w-[242px]'
      }`}
    >
      {/* Logo */}
      <div className={`${collapsed ? 'px-3 pt-5 pb-4' : 'px-6 pt-7 pb-6'}`}>
        <BrandLogo width={collapsed ? 32 : 130} />
      </div>

      <div className="h-px bg-white/10" />

      {/* Nav */}
      <nav
        className={`flex-1 ${
          collapsed ? 'px-2' : 'px-3'
        } py-5 space-y-1 overflow-y-auto`}
      >
        {isCollaborator || isClinic ? (
          visibleItems.map((item) => <NavBtn key={item.id} item={item} />)
        ) : (
          <>
            <NavBtn item={visibleItems.find((i) => i.id === 'dashboard')!} />

            {operacional.length > 0 && (
              <>
                <div className="pt-5 pb-2 px-3">
                  {!collapsed && (
                    <span className="text-[9px] font-mono text-white/65 uppercase tracking-widest">
                      Operacional
                    </span>
                  )}
                  {collapsed && <div className="h-px bg-white/10" />}
                </div>
                {operacional.map((item) => (
                  <NavBtn key={item.id} item={item} />
                ))}
              </>
            )}

            {configuracao.length > 0 && (
              <>
                <div className="pt-5 pb-2 px-3">
                  {!collapsed && (
                    <span className="text-[9px] font-mono text-white/65 uppercase tracking-widest">
                      Configuração
                    </span>
                  )}
                  {collapsed && <div className="h-px bg-white/10" />}
                </div>
                {configuracao.map((item) => (
                  <NavBtn key={item.id} item={item} />
                ))}
              </>
            )}
          </>
        )}
      </nav>

      <div className="h-px bg-white/10" />

      {/* User */}
      <div className={`${collapsed ? 'px-2 py-4' : 'px-5 py-5'}`}>
        {collapsed ? (
          <div className="flex flex-col items-center gap-2">
            <Avatar name={user.name} size="sm" />
            <button
              onClick={onLogout}
              title="Terminar sessão"
              className="text-white/65 hover:text-red-300 transition-colors text-xs"
            >
              ⎋
            </button>
          </div>
        ) : (
          <>
            <div className="flex items-center gap-2.5 mb-3">
              <Avatar name={user.name} size="sm" />
              <div className="min-w-0 flex-1">
                <p className="text-[12px] font-medium text-white truncate">
                  {user.name}
                </p>
                <RoleBadge role={user.role} />
              </div>
            </div>
            <button
              onClick={onLogout}
              className="w-full text-left text-[11px] text-white/65 hover:text-red-300 transition-colors py-0.5"
            >
              Terminar sessão
            </button>
          </>
        )}
      </div>
    </aside>
  )
}

// ─── Mobile overlay sidebar ───────────────────────────────────────────────────

function MobileDrawer({
  open,
  onClose,
  children,
}: {
  open: boolean
  onClose: () => void
  children: React.ReactNode
}) {
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [onClose])

  if (!open) return null

  return (
    <div className="fixed inset-0 z-50 flex">
      <div
        className="absolute inset-0 bg-black/60 backdrop-blur-sm"
        onClick={onClose}
      />
      <div className="relative z-10 flex-shrink-0">{children}</div>
    </div>
  )
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

function TopBar({
  user,
  title,
  subtitle,
  onHamburger,
  showHamburger,
}: {
  user: User
  title: string
  subtitle?: string
  onHamburger: () => void
  showHamburger: boolean
}) {
  const [search, setSearch] = useState('')
  return (
    <header className="flex h-[76px] items-center justify-between px-4 md:px-[35px] border-b border-[#E5E7EB] bg-[#FFFFFF] flex-shrink-0">
      <div className="flex items-center gap-3">
        {showHamburger && (
          <button
            onClick={onHamburger}
            className="p-2 -ml-1 text-[#475569] hover:text-[#1F2937] transition-colors rounded-sm hover:bg-slate-100"
          >
            <span className="block w-4 space-y-1">
              <span className="block h-px bg-current" />
              <span className="block h-px bg-current" />
              <span className="block h-px bg-current" />
            </span>
          </button>
        )}
        <div>
          <h1 className="text-[15px] md:text-[17px] font-serif text-[#1F2937] leading-tight">
            {title}
          </h1>
          {subtitle && (
            <p className="text-[10px] md:text-[11px] text-[#6B7280] mt-0.5 hidden sm:block">
              {subtitle}
            </p>
          )}
        </div>
      </div>
      <div className="flex items-center gap-2 md:gap-3">
        <div className="relative hidden lg:block">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-[#6B7280] text-xs">
            ⌕
          </span>
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Pesquisa rápida..."
            className="w-48 xl:w-52 pl-8 pr-3 py-2 bg-[#FFFFFF] border border-[#E5E7EB] rounded-sm text-[12px] text-[#1F2937] placeholder-[#9CA3AF] focus:border-[#C9A227]/50 focus:outline-none transition-colors"
          />
        </div>
        <DesktopNotifications key={`${user.role}:${user.id}`} user={user} />
        <ThemeToggle />
      </div>
    </header>
  )
}

function DesktopAdminGuard({ onLogout }: { onLogout: () => void }) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-[#F3F4F6] p-6">
      <div className="fixed top-5 right-5">
        <ThemeToggle />
      </div>
      <div className="w-full max-w-lg bg-[#FFFFFF] border border-[#E5E7EB] rounded-xl p-8 text-center shadow-sm">
        <div className="w-12 h-12 rounded-full bg-[#C9A227]/15 border border-[#C9A227]/30 flex items-center justify-center mx-auto text-[#8A6F14] text-xl">
          ▣
        </div>
        <h1 className="text-[22px] font-serif text-[#1F2937] mt-5">
          Acesso exclusivo Desktop
        </h1>
        <p className="text-[13px] text-[#475569] leading-6 mt-3">
          O Backoffice de Administração requer um ecrã de computador (Desktop).
          Por favor, aceda através de um dispositivo com resolução mínima de
          1024px.
        </p>
        <button
          onClick={onLogout}
          className="mt-6 px-4 py-2.5 border border-[#D1D5DB] rounded-md text-[12px] text-[#475569] hover:border-[#C9A227]"
        >
          Terminar sessão
        </button>
      </div>
    </div>
  )
}

// ─── App Shell ────────────────────────────────────────────────────────────────

export default function App() {
  useMockWorkState()
  const [user, setUser] = useState<User | null>(null)
  const [activeSection, setActiveSection] = useState<AppSection>('dashboard')
  const [selectedWorkId, setSelectedWorkId] = useState<string | null>(null)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const [route, setRoute] = useState(() => window.location.hash || '#/')

  const windowWidth = useWindowWidth()
  const adminDesktopBlocked = useMediaQuery('(max-width: 1023px)')
  // < 768: hamburger + drawer; 768-1024: icon-only sidebar; >= 1024: full sidebar
  const isMobileLayout = windowWidth < 768
  const isTabletLayout = windowWidth >= 768 && windowWidth < 1024
  const sidebarCollapsed = isTabletLayout
  const showHamburger = isMobileLayout

  useEffect(() => {
    const onHashChange = () => setRoute(window.location.hash || '#/')
    window.addEventListener('hashchange', onHashChange)
    return () => window.removeEventListener('hashchange', onHashChange)
  }, [])

  useEffect(() => {
    if (!user) return

    const routeConfig = {
      admin: {
        prefix: '#/admin/',
        fallback: '#/admin/dashboard',
        sections: [
          'dashboard',
          'trabalhos',
          'clientes',
          'colaboradores',
          'processos',
          'tipos',
          'configuracoes',
          'atividades',
        ],
      },
      colaborador: {
        prefix: '#/colaborador/',
        fallback: '#/colaborador/inicio',
        sections: ['inicio', 'disponiveis', 'meus', 'prazos'],
      },
      clinica: {
        prefix: '#/clinica/',
        fallback: '#/clinica/inicio',
        sections: ['inicio', 'encomendas', 'alertas', 'conta'],
      },
    } as const

    const config = routeConfig[user.role]
    if (!route.startsWith(config.prefix)) {
      window.location.hash = config.fallback
      setRoute(config.fallback)
      return
    }

    const segment = route.replace(config.prefix, '').split('/')[0]
    if (config.sections.some((section) => section === segment)) {
      setActiveSection(segment as AppSection)
      setSelectedWorkId(null)
    }
  }, [route, user])

  const navigate = (nextRoute: string) => {
    window.location.hash = nextRoute
    setRoute(nextRoute)
  }

  const handleLabLogin = (nextUser: User) => {
    setUser(nextUser)
    setActiveSection(
      nextUser.role === 'colaborador'
        ? 'inicio'
        : nextUser.role === 'clinica'
          ? 'inicio'
          : 'dashboard',
    )
    setSelectedWorkId(null)
    navigate(
      nextUser.role === 'admin'
        ? '#/admin/dashboard'
        : nextUser.role === 'clinica'
          ? '#/clinica/inicio'
          : nextUser.role === 'colaborador'
            ? '#/colaborador/inicio'
            : '#/laboratorio/dashboard',
    )
  }

  if (!user && (route === '#/' || route === '#' || route === '')) {
    return <PublicLanding onPortal={() => navigate('#/entrar')} />
  }

  if (!user)
    return <Login onLogin={handleLabLogin} onBack={() => navigate('#/')} />

  if (user.role === 'admin' && adminDesktopBlocked) {
    return (
      <DesktopAdminGuard
        onLogout={() => {
          setUser(null)
          navigate('#/entrar')
        }}
      />
    )
  }

  const handleSelectWork = (id: string) => {
    setSelectedWorkId(id)
    if (user.role !== 'colaborador') setActiveSection('trabalhos')
  }

  const handleNav = (section: AppSection | string) => {
    setActiveSection(section as AppSection)
    setSelectedWorkId(null)
    setDrawerOpen(false)
    if (user.role === 'admin') navigate(`#/admin/${section}`)
    if (user.role === 'clinica') navigate(`#/clinica/${section}`)
    if (user.role === 'colaborador') navigate(`#/colaborador/${section}`)
  }

  const collaboratorTitles: Record<CollaboratorView, string> = {
    inicio: 'Início',
    disponiveis: 'Trabalhos Disponíveis',
    meus: 'Os Meus Trabalhos',
    prazos: 'Prazos',
  }
  const collaboratorSection = (
    ['inicio', 'disponiveis', 'meus', 'prazos'] as AppSection[]
  ).includes(activeSection)
    ? (activeSection as CollaboratorView)
    : 'inicio'
  const clinicTitles: Record<ClinicDesktopView, string> = {
    inicio: 'Início',
    encomendas: 'Encomendas',
    alertas: 'Alertas',
    conta: 'Conta',
  }
  const clinicSection = (
    ['inicio', 'encomendas', 'alertas', 'conta'] as AppSection[]
  ).includes(activeSection)
    ? (activeSection as ClinicDesktopView)
    : 'inicio'
  const { title, subtitle } = selectedWorkId
    ? { title: 'Trabalhos', subtitle: 'Detalhe do trabalho' }
    : user.role === 'colaborador'
      ? { title: collaboratorTitles[collaboratorSection], subtitle: undefined }
      : user.role === 'clinica'
        ? { title: clinicTitles[clinicSection], subtitle: undefined }
        : PAGE_TITLES[activeSection as NavSection]

  const sidebarEl = (
    <Sidebar
      user={user}
      active={
        user.role === 'colaborador'
          ? collaboratorSection
          : user.role === 'clinica'
            ? clinicSection
            : activeSection
      }
      onNav={handleNav}
      onLogout={() => {
        setUser(null)
        navigate('#/entrar')
      }}
      collapsed={isMobileLayout ? false : sidebarCollapsed}
      onClose={() => setDrawerOpen(false)}
    />
  )

  return (
    <div className="h-screen flex overflow-hidden bg-[#F3F4F6]">
      {/* Sidebar: desktop/tablet inline, mobile in drawer */}
      {!isMobileLayout && sidebarEl}

      {isMobileLayout && (
        <MobileDrawer open={drawerOpen} onClose={() => setDrawerOpen(false)}>
          {sidebarEl}
        </MobileDrawer>
      )}

      <div className="backoffice-main flex-1 flex flex-col overflow-hidden min-w-0">
        <TopBar
          user={user}
          title={title}
          subtitle={subtitle}
          onHamburger={() => setDrawerOpen(true)}
          showHamburger={showHamburger}
        />

        {/* Views */}
        {selectedWorkId &&
        (activeSection === 'trabalhos' || user.role === 'colaborador') ? (
          <TrabalhoDetalhe
            workId={selectedWorkId}
            onBack={() => setSelectedWorkId(null)}
            userRole={user.role}
            currentUser={user}
            collaboratorView={
              user.role === 'colaborador' ? collaboratorSection : undefined
            }
          />
        ) : (
          <>
            {user.role === 'colaborador' ? (
              <CollaboratorDashboard
                user={user}
                activeView={collaboratorSection}
                onViewChange={handleNav}
                onSelectWork={handleSelectWork}
              />
            ) : user.role === 'clinica' ? (
              <ClinicDesktopDashboard
                user={user}
                activeView={clinicSection}
                onViewChange={handleNav}
              />
            ) : (
              activeSection === 'dashboard' && (
                <Dashboard onSelectWork={handleSelectWork} onNav={handleNav} />
              )
            )}
            {activeSection === 'trabalhos' && (
              <Trabalhos
                onSelectWork={handleSelectWork}
                canEdit={user.role === 'admin'}
              />
            )}
            {activeSection === 'clientes' && (
              <Clientes onSelectWork={handleSelectWork} />
            )}
            {activeSection === 'colaboradores' && (
              <Colaboradores onSelectWork={handleSelectWork} />
            )}
            {activeSection === 'processos' && <Processos />}
            {activeSection === 'tipos' && <TiposTrabalho />}
            {activeSection === 'configuracoes' && <Configuracoes />}
            {activeSection === 'atividades' && <AuditLogs />}
          </>
        )}
      </div>
    </div>
  )
}
