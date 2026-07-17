const moments = [
  {
    number: "01",
    title: "Pair",
    copy: "Apple TV opens the system picker. A nearby iPad approves a secure local session.",
  },
  {
    number: "02",
    title: "Explore privately",
    copy: "Browse upcoming moments, type, and inspect detail without interrupting the room.",
  },
  {
    number: "03",
    title: "Send with intent",
    copy: "Put a selection or message on TV only after an explicit, human-readable action.",
  },
  {
    number: "04",
    title: "Stay in sync",
    copy: "TV-owned revisions and snapshots keep both interfaces coherent through reconnects.",
  },
];

const safeguards = [
  "Versioned protocol envelopes",
  "Authoritative TV state",
  "Stale-message protection",
  "Listener recovery",
  "Validated payload bounds",
  "Length-prefixed framing",
];

export default function Home() {
  return (
    <main>
      <div className="site-glow" aria-hidden="true" />
      <header className="nav shell">
        <a className="brand" href="#top" aria-label="TV Companion Kit home">
          <span className="brand-mark" aria-hidden="true">
            <span />
            <span />
          </span>
          <span>TV Companion Kit</span>
        </a>
        <nav aria-label="Primary navigation">
          <a href="#experience">Experience</a>
          <a href="#architecture">Architecture</a>
          <a href="#github">GitHub</a>
        </nav>
      </header>

      <section className="hero shell" id="top">
        <div className="hero-copy">
          <p className="eyebrow">
            <span className="live-dot" aria-hidden="true" />
            Native. Local. Intentional.
          </p>
          <h1>
            The TV is the
            <span> shared stage.</span>
            <br />
            The iPad is the
            <span> private console.</span>
          </h1>
          <p className="hero-description">
            Build synchronized iPad companion experiences for Apple TV—without
            a backend, browser, or mirrored display.
          </p>
          <div className="hero-actions">
            <a className="button primary" href="#experience">
              Explore the experience
              <span aria-hidden="true">↓</span>
            </a>
            <a className="button secondary" href="#github">
              View the project
              <span aria-hidden="true">↗</span>
            </a>
          </div>
          <ul className="proof" aria-label="Project highlights">
            <li><strong>12</strong> tests passing</li>
            <li><strong>0</strong> backend services</li>
            <li><strong>2</strong> native surfaces</li>
          </ul>
        </div>

        <div className="system-visual" aria-label="Apple TV and iPad companion system">
          <div className="stage-panel">
            <div className="panel-topline">
              <span>SHARED STAGE</span>
              <span className="status"><i /> LIVE</span>
            </div>
            <div className="stage-content">
              <div className="stage-icon" aria-hidden="true">⌁</div>
              <div>
                <small>NOW ON TV · SEND WITH INTENT</small>
                <h2>Put the right moment on the big screen.</h2>
                <p>Canonical state lives here.</p>
              </div>
            </div>
            <div className="stage-foot">
              <span>TVCompanionTV</span>
              <span>revision 24</span>
            </div>
          </div>

          <div className="signal" aria-hidden="true">
            <span className="signal-line" />
            <span className="signal-pulse" />
          </div>

          <div className="console-panel">
            <div className="panel-topline">
              <span>PRIVATE CONSOLE</span>
              <span className="lock">● SECURE</span>
            </div>
            <div className="console-now">
              <small>NOW ON TV</small>
              <strong>Send with intent</strong>
            </div>
            <div className="queue-label">EXPLORE WHAT IS NEXT</div>
            <div className="queue-item active"><span>01</span> Pair <b>ON TV</b></div>
            <div className="queue-item"><span>02</span> Explore privately <b>PUT ON TV</b></div>
            <div className="queue-item"><span>03</span> Stay in sync <b>PUT ON TV</b></div>
            <div className="private-draft">
              <span>PRIVATE DRAFT</span>
              <button type="button" tabIndex={-1}>Share on TV</button>
            </div>
          </div>
        </div>
      </section>

      <section className="experience shell" id="experience">
        <div className="section-heading">
          <div>
            <p className="eyebrow">A reusable interaction model</p>
            <h2>One loop. Four clear moments.</h2>
          </div>
          <p>
            The handheld device adds personal context and precision without
            turning into a remote-shaped copy of the TV.
          </p>
        </div>
        <div className="moment-grid">
          {moments.map((moment) => (
            <article className="moment-card" key={moment.number}>
              <span>{moment.number}</span>
              <h3>{moment.title}</h3>
              <p>{moment.copy}</p>
              <i aria-hidden="true" />
            </article>
          ))}
        </div>
      </section>

      <section className="principle shell">
        <div className="principle-label">DESIGN PRINCIPLE 01</div>
        <blockquote>
          “Private by default. Shared only with intent.”
        </blockquote>
        <p>
          Browsing, drafting, and previewing stay on iPad. The verbs make scope
          unmistakable: <strong>Put on TV</strong>, <strong>Share on TV</strong>,
          and <strong>Clear from TV</strong>.
        </p>
      </section>

      <section className="architecture shell" id="architecture">
        <div className="architecture-copy">
          <p className="eyebrow">Native architecture</p>
          <h2>Two interfaces.<br />One canonical session.</h2>
          <p>
            DeviceDiscoveryUI handles user-approved discovery. Network.framework
            carries encrypted, semantic messages. Apple TV applies commands and
            publishes revisioned snapshots.
          </p>
          <div className="tech-chips" aria-label="Technologies">
            <span>DeviceDiscoveryUI</span>
            <span>Network.framework</span>
            <span>SwiftUI</span>
            <span>Codable</span>
          </div>
        </div>
        <div className="architecture-card">
          <div className="architecture-node tv-node">
            <small>SESSION HOST</small>
            <strong>Apple TV</strong>
            <span>DevicePicker · NWConnection</span>
          </div>
          <div className="protocol-rail">
            <span>commands →</span>
            <i />
            <span>← snapshots</span>
          </div>
          <div className="architecture-node pad-node">
            <small>COMPANION</small>
            <strong>iPad</strong>
            <span>NWListener · touch UI</span>
          </div>
          <div className="safeguards">
            {safeguards.map((item) => <span key={item}>✓ {item}</span>)}
          </div>
        </div>
      </section>

      <section className="github shell" id="github">
        <div>
          <p className="eyebrow">Open sample project</p>
          <h2>Built to study, fork, and extend.</h2>
          <p>
            Separate iPadOS and tvOS targets, a shared versioned protocol, an
            authoritative reducer, diagnostics, and standalone tests—all in one
            focused Xcode project.
          </p>
        </div>
        <div className="github-actions">
          <a
            className="button primary"
            href="https://github.com/mattcassinelli/TVCompanionKit"
            target="_blank"
            rel="noreferrer"
          >
            View source on GitHub <span aria-hidden="true">↗</span>
          </a>
          <p>The complete sample project is available on GitHub.</p>
        </div>
      </section>

      <footer className="footer shell">
        <a className="brand" href="#top">
          <span className="brand-mark" aria-hidden="true"><span /><span /></span>
          <span>TV Companion Kit</span>
        </a>
        <p>Built by Supercomputer Studios.</p>
        <span>iPadOS · tvOS · SwiftUI</span>
      </footer>
    </main>
  );
}
