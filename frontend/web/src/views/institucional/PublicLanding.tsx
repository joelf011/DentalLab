import HERO_IMAGE from '../../assets/laboratoryHero.svg'
import { useState, type FormEvent } from 'react'
import { ThemeToggle } from '../../theme'
import BrandLogo from '../../components/BrandLogo'
import { AppIcon } from '../../components/icons'
import { WORK_TYPES } from '../../data'
import '../PublicLanding.css'

export default function PublicLanding({ onPortal }: { onPortal: () => void }) {
  const [submitted, setSubmitted] = useState(false)
  const [imageFailed, setImageFailed] = useState(false)
  const [privacy, setPrivacy] = useState(false)
  const go = (id: string) =>
    document
      .getElementById(id)
      ?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    setSubmitted(true)
  }
  return (
    <div className="lab-site" id="inicio">
      <a
        className="lab-skip"
        href="#conteudo"
        onClick={(event) => {
          event.preventDefault()
          go('conteudo')
          document.getElementById('conteudo')?.focus()
        }}
      >
        Saltar para o conteúdo
      </a>
      <header className="lab-nav">
        <div className="lab-wrap lab-nav-inner">
          <button
            className="lab-brand"
            onClick={() => go('inicio')}
            aria-label="Voltar ao início"
          >
            <BrandLogo width={112} />
          </button>
          <nav aria-label="Navegação principal" className="lab-nav-links">
            <button onClick={() => go('aplicacao')}>A aplicação</button>
            <button onClick={() => go('trabalhos')}>O que fazemos</button>
            <button onClick={() => go('contacto')}>Contacto</button>
          </nav>
          <div className="lab-nav-actions">
            <ThemeToggle />
            <button onClick={onPortal} className="lab-button lab-button-small">
              Aceder ao portal <span aria-hidden="true">↗</span>
            </button>
          </div>
        </div>
      </header>
      <main id="conteudo" tabIndex={-1}>
        <section className="lab-wrap lab-hero">
          <div className="lab-hero-copy">
            <p className="lab-eyebrow">Laboratório de Prótese Dentária</p>
            <h1>
              O detalhe faz
              <br />o <em>sorriso.</em>
            </h1>
            <p className="lab-intro">
              Próteses dentárias feitas à medida.
              <br />
              Para clínicas e consultórios que cuidam de cada detalhe.
            </p>
            <button className="lab-button" onClick={() => go('contacto')}>
              Contacto <span aria-hidden="true">↗</span>
            </button>
          </div>
          <figure className="lab-hero-image">
            {!imageFailed ? (
              <img
                src={HERO_IMAGE}
                alt="Mãos com luvas a trabalhar num modelo de arcada dentária"
                fetchPriority="high"
                onError={() => setImageFailed(true)}
              />
            ) : (
              <div className="lab-image-fallback">
                <BrandLogo width={230} />
                <p>Prótese dentária feita à medida.</p>
              </div>
            )}
            <figcaption>
              <span>Da clínica ao laboratório.</span>
              <strong>Cuidado em cada etapa.</strong>
              <small>Fotografia ilustrativa · Cosmin Ursea / Unsplash</small>
            </figcaption>
          </figure>
        </section>

        <section className="lab-app-section" id="aplicacao">
          <div className="lab-wrap lab-app-grid">
            <div className="lab-app-copy">
              <p className="lab-eyebrow">O laboratório, mais perto</p>
              <h2>
                As suas encomendas.
                <br />
                <em>Na palma da mão.</em>
              </h2>
              <p>
                Crie encomendas, envie fotografias e ficheiros e acompanhe os
                seus trabalhos. Com a aplicação, a sua clínica mantém o contacto
                com o laboratório num só lugar.
              </p>
              <ul className="lab-benefits">
                <li>
                  <AppIcon name="plus" />
                  Crie encomendas com vários trabalhos
                </li>
                <li>
                  <AppIcon name="layers" />
                  Acompanhe o estado de cada encomenda
                </li>
                <li>
                  <AppIcon name="file-text" />
                  Partilhe informação com o laboratório
                </li>
              </ul>
            </div>
            <figure className="lab-app-visual">
              <div className="w-full max-w-[460px] rounded-[28px] border border-[var(--line)] bg-[var(--surface)] p-5 shadow-[0_18px_50px_rgba(17,24,39,0.08)]">
                <div className="mb-5 flex items-center justify-between gap-3">
                  <div>
                    <p className="text-[10px] font-mono uppercase tracking-[0.18em] text-[var(--muted)]">
                      Dashboard
                    </p>
                    <h3 className="mt-1 text-base font-semibold text-[var(--ink)]">
                      Fluxo ativo
                    </h3>
                  </div>
                  <span className="rounded-full bg-[var(--gold-soft)] px-2 py-1 text-[10px] font-semibold text-[var(--gold-ink)]">
                    8 em curso
                  </span>
                </div>

                <div className="space-y-3">
                  {[
                    ['Gestão', '4 encomendas'],
                    ['Modelação', '2 em revisão'],
                    ['Expedição', '2 a preparar'],
                  ].map(([label, value]) => (
                    <div
                      key={label}
                      className="rounded-xl border border-[var(--line)] bg-[var(--paper)] p-3"
                    >
                      <div className="flex items-center justify-between gap-3">
                        <span className="text-[11px] text-[var(--muted)]">
                          {label}
                        </span>
                        <span className="text-[10px] font-semibold text-[var(--ink)]">
                          {value}
                        </span>
                      </div>
                      <div className="mt-3 h-2 overflow-hidden rounded-full bg-[var(--line)]">
                        <div className="h-full w-2/3 rounded-full bg-[var(--gold)]" />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <figcaption className="lab-preview-caption">
                Plataforma web desktop, tablet e browser para acompanhamento em
                tempo real.
              </figcaption>
            </figure>
          </div>
        </section>

        <section className="lab-wrap lab-services" id="trabalhos">
          <div className="lab-section-heading">
            <div>
              <p className="lab-eyebrow">O que fazemos</p>
              <h2>
                Um trabalho para
                <br />
                <em>cada necessidade.</em>
              </h2>
            </div>
            <p>
              Produzimos soluções de prótese dentária a partir das indicações da
              sua clínica. Conheça os tipos de trabalho disponíveis no nosso
              catálogo.
            </p>
          </div>
          <div className="lab-services-grid">
            {WORK_TYPES.map((type, index) => (
              <article key={type.id} className="lab-service">
                <span>{String(index + 1).padStart(2, '0')}</span>
                <h3>{type.name}</h3>
                <AppIcon name="layers" />
              </article>
            ))}
          </div>
          <p className="lab-services-note">
            Tem dúvidas sobre um trabalho?{' '}
            <button onClick={() => go('contacto')}>Fale connosco →</button>
          </p>
        </section>

        <section className="lab-contact-section" id="contacto">
          <div className="lab-wrap lab-contact-grid">
            <div>
              <p className="lab-eyebrow">Contacto</p>
              <h2>
                Vamos falar
                <br />
                <em>do próximo trabalho?</em>
              </h2>
              <p className="lab-contact-intro">
                Peça informações sobre os nossos trabalhos ou esclareça dúvidas
                antes de criar uma encomenda.
              </p>
            </div>
            <form onSubmit={submit} className="lab-contact-form">
              <div className="lab-form-grid">
                <label>
                  Clínica ou consultório
                  <input
                    name="clinic"
                    required
                    autoComplete="organization"
                    placeholder="Nome da clínica"
                  />
                </label>
                <label>
                  Nome de contacto
                  <input
                    name="name"
                    required
                    autoComplete="name"
                    placeholder="O seu nome"
                  />
                </label>
                <label>
                  E-mail
                  <input
                    name="email"
                    required
                    type="email"
                    autoComplete="email"
                    placeholder="nome@clinica.pt"
                  />
                </label>
                <label>
                  Telefone <span>(opcional)</span>
                  <input
                    name="phone"
                    type="tel"
                    autoComplete="tel"
                    placeholder="Número de contacto"
                  />
                </label>
                <label className="lab-field-wide">
                  Assunto
                  <select name="subject" required defaultValue="">
                    <option value="" disabled>
                      Como podemos ajudar?
                    </option>
                    <option>Informações sobre trabalhos</option>
                    <option>Pedido de orçamento</option>
                    <option>Outro assunto</option>
                  </select>
                </label>
                <label className="lab-field-wide">
                  Mensagem
                  <textarea
                    name="message"
                    required
                    rows={4}
                    placeholder="Conte-nos o que precisa…"
                  />
                </label>
              </div>
              <p className="lab-form-help">
                Não inclua dados pessoais de pacientes nesta mensagem.
              </p>
              <button className="lab-button" type="submit">
                Enviar mensagem <span aria-hidden="true">↗</span>
              </button>
              {submitted && (
                <p role="status" className="lab-form-feedback">
                  Mensagem validada nesta demonstração. O envio ao laboratório
                  ficará disponível na versão final.
                </p>
              )}
            </form>
          </div>
        </section>
      </main>
      <footer className="lab-footer">
        <div className="lab-wrap lab-footer-main">
          <div>
            <BrandLogo width={135} />
            <p>
              Laboratório Catarina Domingos
              <br />
              Prótese dentária feita à medida.
            </p>
          </div>
          <nav aria-label="Navegação do rodapé">
            <h3>Explore</h3>
            <button onClick={() => go('aplicacao')}>A plataforma</button>
            <button onClick={() => go('trabalhos')}>Os nossos trabalhos</button>
            <button onClick={() => go('contacto')}>Contacto</button>
          </nav>
          <nav aria-label="Acesso ao portal">
            <h3>A sua clínica</h3>
            <button onClick={onPortal}>Aceder ao portal</button>
            <button
              onClick={() => setPrivacy((v) => !v)}
              aria-expanded={privacy}
            >
              Privacidade
            </button>
          </nav>
        </div>
        {privacy && (
          <div className="lab-wrap lab-privacy">
            <h3>Privacidade neste protótipo</h3>
            <p>
              O formulário demonstra a experiência de contacto e não envia os
              dados ao laboratório. Os dados de demonstração e as preferências
              da aplicação podem ficar guardados neste navegador. A política de
              privacidade do serviço será disponibilizada antes do lançamento.
            </p>
            <button onClick={() => setPrivacy(false)}>Fechar</button>
          </div>
        )}
        <div className="lab-wrap lab-footer-bottom">
          <span>
            © {new Date().getFullYear()} Laboratório Catarina Domingos
          </span>
          <span>Todos os direitos reservados.</span>
          <button onClick={() => go('inicio')}>Voltar ao topo ↑</button>
        </div>
      </footer>
    </div>
  )
}
