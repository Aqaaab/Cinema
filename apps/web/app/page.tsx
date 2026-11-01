import Link from "next/link";

const principles = [
  {
    number: "01",
    title: "Rights before playback",
    description:
      "A title is playable only when its source, permitted method, and territory have been verified.",
  },
  {
    number: "02",
    title: "Know before you press play",
    description:
      "See supported languages, subtitles, accessibility details, and provider status up front.",
  },
  {
    number: "03",
    title: "Your library stays yours",
    description:
      "Build watchlists and personal collections designed to sync across Android and the web.",
  },
];

const platforms = [
  { name: "Android", detail: "Native Kotlin + Jetpack Compose", status: "Starter app" },
  { name: "Web", detail: "Next.js + TypeScript", status: "Starter app" },
  { name: "API", detail: "Go modular service", status: "Health endpoints" },
];

export default function HomePage() {
  return (
    <main>
      <nav className="nav shell" aria-label="Main navigation">
        <Link className="brand" href="/" aria-label="Cinema home">
          <span className="brand-mark">C</span><span>CINEMA</span>
        </Link>
        <div className="nav-links">
          <a href="#principles">Why Cinema</a>
          <a href="#platforms">Platforms</a>
          <a className="nav-github" href="https://github.com/Aqaaab/Cinema" target="_blank" rel="noreferrer">
            GitHub <span aria-hidden="true">↗</span>
          </a>
        </div>
      </nav>

      <section className="hero shell">
        <div className="hero-copy">
          <p className="eyebrow"><span className="pulse" /> OPEN-SOURCE ENTERTAINMENT</p>
          <h1>Find what you can actually <em>watch.</em></h1>
          <p className="hero-subtitle">
            One home for films, series, and animation — with clear sources, honest regional
            availability, and rights transparency built in.
          </p>
          <div className="hero-actions">
            <a className="button button-primary" href="https://github.com/Aqaaab/Cinema">
              Explore the project <span aria-hidden="true">↗</span>
            </a>
            <a className="button button-secondary" href="#principles">Our principles</a>
          </div>
          <p className="hero-note">Free to use. Open source. No unauthorized streams.</p>
        </div>

        <div className="hero-panel" aria-label="Illustration of a verified title availability card">
          <div className="panel-top">
            <span className="panel-kicker">CINEMA / AVAILABILITY</span>
            <span className="panel-status"><i /> RIGHTS-AWARE</span>
          </div>
          <div className="panel-art">
            <div className="orbit orbit-one" />
            <div className="orbit orbit-two" />
            <div className="art-sun" />
            <div className="art-horizon" />
            <div className="art-caption">A BETTER WAY TO DISCOVER</div>
          </div>
          <div className="panel-details">
            <div><p className="detail-label">SOURCE STATUS</p><p className="detail-value">Verified before playback</p></div>
            <span className="verified-icon" aria-hidden="true">✓</span>
          </div>
          <div className="panel-foot">
            <span>Territory-aware</span><span>•</span><span>Transparent</span><span>•</span><span>Open</span>
          </div>
        </div>
      </section>

      <section className="trust-strip shell" aria-label="Cinema commitments">
        <div><strong>01</strong><span>Rights-first catalogue</span></div>
        <div><strong>02</strong><span>One personal library</span></div>
        <div><strong>03</strong><span>Built for real devices</span></div>
      </section>

      <section className="section shell" id="principles">
        <div className="section-heading">
          <p className="eyebrow">THE DIFFERENCE</p>
          <h2>Discovery should come with <em>proof.</em></h2>
          <p>Not just a poster and a play button. The facts that help you choose confidently.</p>
        </div>
        <div className="principle-grid">
          {principles.map((item) => (
            <article className="principle-card" key={item.number}>
              <span className="card-number">{item.number}</span>
              <h3>{item.title}</h3>
              <p>{item.description}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="platform-section" id="platforms">
        <div className="shell">
          <div className="section-heading section-heading-row">
            <div><p className="eyebrow">ONE PRODUCT, THREE LAYERS</p><h2>Built to work <em>together.</em></h2></div>
            <p>Small, independent components. One consistent experience.</p>
          </div>
          <div className="platform-grid">
            {platforms.map((platform) => (
              <article className="platform-card" key={platform.name}>
                <div className="platform-icon" aria-hidden="true">
                  {platform.name === "Android" ? "A" : platform.name === "Web" ? "W" : "API"}
                </div>
                <div><h3>{platform.name}</h3><p>{platform.detail}</p></div>
                <span className="platform-status">{platform.status}</span>
              </article>
            ))}
          </div>
        </div>
      </section>

      <section className="closing shell">
        <p className="eyebrow">EARLY DEVELOPMENT</p>
        <h2>Help build a more <em>honest</em> way to watch.</h2>
        <p>Cinema is in its foundation phase. Follow the work, inspect the code, and help shape the roadmap.</p>
        <a className="button button-primary" href="https://github.com/Aqaaab/Cinema">
          Contribute on GitHub <span aria-hidden="true">↗</span>
        </a>
      </section>

      <footer className="footer shell">
        <Link className="brand" href="/"><span className="brand-mark">C</span><span>CINEMA</span></Link>
        <p>Open source does not mean rights-free. We verify before we play.</p>
        <span>© {new Date().getFullYear()} Cinema</span>
      </footer>
    </main>
  );
}
