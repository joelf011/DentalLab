import { useState, type FormEvent } from 'react'
import heroImage from '../assets/hero.png'
import { ThemeToggle } from '../theme'

interface PublicLandingProps {
  onPortal: () => void
}

const SERVICES = [
  { number: '01', title: 'Prótese Fixa', description: 'Coroas, facetas e pontes com precisão marginal e integração estética.' },
  { number: '02', title: 'Prótese Removível', description: 'Soluções funcionais em acrílico e estruturas metálicas personalizadas.' },
  { number: '03', title: 'CAD/CAM', description: 'Fluxos digitais, fresagem e impressão para maior previsibilidade clínica.' },
  { number: '04', title: 'Alinhadores', description: 'Planeamento e produção digital orientados à evolução do tratamento.' },
]

export default function PublicLanding({ onPortal }: PublicLandingProps) {
  const [submitted, setSubmitted] = useState(false)

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSubmitted(true)
    event.currentTarget.reset()
  }

  const scrollToContact = () => {
    document.querySelector('#contacto')?.scrollIntoView({ behavior: 'smooth' })
  }

  return (
    <div className="public-site min-h-screen">
      <header className="public-nav sticky top-0 z-40 border-b backdrop-blur-xl">
        <div className="mx-auto flex max-w-[1440px] items-center justify-between px-5 py-4 md:px-10 lg:px-16">
          <button type="button" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })} className="flex items-center gap-3 text-left">
            <span className="public-logo flex h-9 w-9 items-center justify-center rounded-sm font-semibold">L</span>
            <span>
              <span className="block text-[12px] font-semibold tracking-wide">Laboratório Catarina Domingos</span>
              <span className="public-muted block text-[9px] uppercase tracking-[0.18em]">Prótese Dentária</span>
            </span>
          </button>
          <div className="flex items-center gap-2">
            <button type="button" onClick={scrollToContact} className="public-nav-link hidden px-3 py-2 text-[12px] font-medium sm:block">Parcerias</button>
            <ThemeToggle />
            <button type="button" onClick={onPortal} className="public-primary rounded-md px-4 py-2.5 text-[12px] font-semibold">Aceder ao Portal</button>
          </div>
        </div>
      </header>

      <main>
        <section className="mx-auto grid min-h-[700px] max-w-[1440px] grid-cols-1 lg:grid-cols-[3fr_2fr]">
          <div className="flex items-center px-6 py-16 md:px-12 lg:px-16 lg:py-24">
            <div className="max-w-3xl">
              <p className="public-gold mb-6 text-[10px] font-semibold uppercase tracking-[0.24em]">Dispositivos médicos personalizados</p>
              <h1 className="text-[42px] font-semibold leading-[1.06] tracking-[-0.035em] md:text-[60px] lg:text-[68px]">
                Precisão artesanal para resultados clínicos de excelência.
              </h1>
              <p className="public-muted mt-7 max-w-2xl text-[15px] leading-7 md:text-[17px]">
                Unimos conhecimento técnico, cerâmica de elevada qualidade e processos digitais para criar soluções protéticas previsíveis, naturais e rigorosamente personalizadas.
              </p>
              <div className="mt-9 flex flex-col gap-3 sm:flex-row">
                <button type="button" onClick={onPortal} className="public-primary rounded-md px-6 py-3.5 text-[13px] font-semibold">Aceder ao Portal</button>
                <button type="button" onClick={scrollToContact} className="public-secondary rounded-md border px-6 py-3.5 text-[13px] font-semibold">Parcerias para Clínicas</button>
              </div>
              <div className="public-rule mt-14 grid max-w-2xl grid-cols-3 border-t pt-6">
                <div><strong className="block text-[20px]">Digital</strong><span className="public-muted text-[10px]">Fluxo integrado</span></div>
                <div><strong className="block text-[20px]">Rigor</strong><span className="public-muted text-[10px]">Controlo técnico</span></div>
                <div><strong className="block text-[20px]">Próximo</strong><span className="public-muted text-[10px]">Apoio às clínicas</span></div>
              </div>
            </div>
          </div>
          <div className="relative min-h-[480px] overflow-hidden lg:min-h-full">
            <img src={heroImage} alt="Técnico dentário a trabalhar numa prótese com instrumentos de precisão" className="absolute inset-0 h-full w-full object-cover" />
            <div className="absolute inset-0 bg-gradient-to-t from-black/45 via-transparent to-black/10" />
            <p className="absolute bottom-5 right-6 text-[9px] text-white/75">Fotografia: Adrian Sulyok / Unsplash</p>
          </div>
        </section>

        <section className="public-section-alt border-y px-6 py-20 md:px-12 lg:px-16">
          <div className="mx-auto max-w-[1312px]">
            <div className="mb-10 max-w-2xl">
              <p className="public-gold text-[10px] font-semibold uppercase tracking-[0.2em]">Competências</p>
              <h2 className="mt-3 text-[30px] font-semibold tracking-[-0.02em] md:text-[38px]">Soluções para cada fase do tratamento.</h2>
            </div>
            <div className="grid grid-cols-1 gap-px overflow-hidden rounded-xl border md:grid-cols-2 xl:grid-cols-4">
              {SERVICES.map(service => (
                <article key={service.title} className="public-card min-h-64 p-6">
                  <span className="public-gold text-[10px] font-mono">{service.number}</span>
                  <h3 className="mt-16 text-[18px] font-semibold">{service.title}</h3>
                  <p className="public-muted mt-3 text-[12px] leading-6">{service.description}</p>
                </article>
              ))}
            </div>
          </div>
        </section>

        <section id="contacto" className="scroll-mt-24 px-6 py-20 md:px-12 lg:px-16">
          <div className="mx-auto grid max-w-[1312px] grid-cols-1 gap-12 lg:grid-cols-[0.85fr_1.15fr]">
            <div>
              <p className="public-gold text-[10px] font-semibold uppercase tracking-[0.2em]">Parcerias clínicas</p>
              <h2 className="mt-3 text-[34px] font-semibold leading-tight tracking-[-0.025em]">Comece uma colaboração com o laboratório.</h2>
              <p className="public-muted mt-5 max-w-lg text-[13px] leading-6">
                Partilhe as necessidades da sua clínica. A nossa equipa entrará em contacto para alinhar protocolos, recolhas e fluxos digitais.
              </p>
              <div className="mt-10 grid gap-3 sm:grid-cols-2 lg:grid-cols-1">
                <div className="public-card rounded-xl border p-5">
                  <p className="public-muted text-[9px] uppercase tracking-wider">Contacto geral</p>
                  <p className="mt-2 text-[13px] font-medium">geral@lcd.pt</p>
                  <p className="public-muted mt-1 text-[11px]">+351 220 000 000</p>
                </div>
                <div className="public-card rounded-xl border p-5">
                  <p className="public-muted text-[9px] uppercase tracking-wider">Horário técnico</p>
                  <p className="mt-2 text-[13px] font-medium">Segunda a Sexta</p>
                  <p className="public-muted mt-1 text-[11px]">09:00–18:00 · Porto, Portugal</p>
                </div>
              </div>
            </div>

            <form onSubmit={handleSubmit} className="public-card rounded-2xl border p-6 md:p-8">
              <div className="grid grid-cols-1 gap-5 md:grid-cols-2">
                <PublicField label="Nome da Clínica"><input required name="clinic" /></PublicField>
                <PublicField label="Médico Prescritor"><input required name="prescriber" /></PublicField>
                <PublicField label="E-mail"><input required type="email" name="email" /></PublicField>
                <PublicField label="Telefone"><input required type="tel" name="phone" /></PublicField>
                <div className="md:col-span-2">
                  <PublicField label="Serviços Pretendidos">
                    <select required name="services" defaultValue="">
                      <option value="" disabled>Selecionar serviços...</option>
                      <option>Prótese Fixa</option>
                      <option>Prótese Removível</option>
                      <option>CAD/CAM</option>
                      <option>Alinhadores</option>
                      <option>Vários serviços</option>
                    </select>
                  </PublicField>
                </div>
                <div className="md:col-span-2">
                  <PublicField label="Mensagem"><textarea required name="message" rows={5} /></PublicField>
                </div>
              </div>
              <div className="mt-6 flex items-center justify-between gap-4">
                <p className="public-muted text-[10px]">{submitted ? 'Pedido enviado. Entraremos em contacto brevemente.' : 'Resposta habitual em 1 dia útil.'}</p>
                <button type="submit" className="public-primary rounded-md px-5 py-3 text-[12px] font-semibold">Enviar pedido</button>
              </div>
            </form>
          </div>
        </section>
      </main>

      <footer className="public-section-alt border-t px-6 py-8 md:px-12 lg:px-16">
        <div className="public-muted mx-auto flex max-w-[1312px] flex-col justify-between gap-3 text-[10px] sm:flex-row">
          <span>© 2025 Laboratório Catarina Domingos</span>
          <span>Dispositivos médicos personalizados · Uso profissional</span>
        </div>
      </footer>
    </div>
  )
}

function PublicField({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="public-field block">
      <span className="public-muted mb-2 block text-[10px] font-medium uppercase tracking-wider">{label}</span>
      {children}
    </label>
  )
}
