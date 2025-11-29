const SUPPORT_EMAIL = "support@100apps.studio";

export default function SupportPage() {
  return (
    <main
      style={{
        minHeight: "100vh",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "2rem"
      }}
    >
      <section
        style={{
          width: "100%",
          maxWidth: "640px",
          backgroundColor: "rgba(15, 23, 42, 0.85)",
          borderRadius: "1.5rem",
          border: "1px solid rgba(148, 163, 184, 0.35)",
          boxShadow:
            "0 24px 60px rgba(15, 23, 42, 0.85), 0 0 0 1px rgba(15, 23, 42, 0.9)",
          padding: "2.5rem 2.25rem"
        }}
      >
        <header style={{ marginBottom: "1.75rem" }}>
          <p
            style={{
              textTransform: "uppercase",
              letterSpacing: "0.18em",
              fontSize: "0.72rem",
              fontWeight: 600,
              color: "#38bdf8",
              marginBottom: "0.75rem"
            }}
          >
            100 Apps Studio
          </p>
          <h1
            style={{
              fontSize: "1.9rem",
              lineHeight: 1.1,
              fontWeight: 700,
              color: "#e5e7eb",
              margin: 0
            }}
          >
            Calendar Play – Support
          </h1>
        </header>

        <p
          style={{
            color: "#9ca3af",
            fontSize: "0.98rem",
            lineHeight: 1.6,
            marginBottom: "1.5rem"
          }}
        >
          Thanks for using <strong>Calendar Play</strong>. If you have questions,
          feedback, or need help with the app, we’re happy to hear from you.
        </p>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: "1.25rem",
            marginBottom: "2rem"
          }}
        >
          <div>
            <h2
              style={{
                fontSize: "0.95rem",
                textTransform: "uppercase",
                letterSpacing: "0.12em",
                color: "#cbd5f5",
                marginBottom: "0.4rem"
              }}
            >
              Email support
            </h2>
            <p
              style={{
                fontSize: "0.95rem",
                color: "#9ca3af",
                marginBottom: "0.35rem"
              }}
            >
              For all support inquiries, contact us at:
            </p>
            <a
              href={`mailto:${SUPPORT_EMAIL}`}
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: "0.4rem",
                fontSize: "0.97rem",
                fontWeight: 500,
                color: "#38bdf8",
                textDecoration: "none"
              }}
            >
              {SUPPORT_EMAIL}
              <span aria-hidden="true" style={{ fontSize: "0.9em" }}>
                ↗
              </span>
            </a>
          </div>

          <div>
            <h2
              style={{
                fontSize: "0.95rem",
                textTransform: "uppercase",
                letterSpacing: "0.12em",
                color: "#cbd5f5",
                marginBottom: "0.4rem"
              }}
            >
              What to include
            </h2>
            <p
              style={{
                fontSize: "0.95rem",
                color: "#9ca3af",
                marginBottom: "0.25rem"
              }}
            >
              To help us respond quickly, please include:
            </p>
            <ul
              style={{
                paddingLeft: "1.2rem",
                color: "#9ca3af",
                fontSize: "0.93rem",
                lineHeight: 1.5,
                margin: 0
              }}
            >
              <li>Your device model (e.g. iPhone, iPad, Apple TV)</li>
              <li>Your iOS / tvOS version</li>
              <li>The version of Calendar Play you&apos;re using</li>
              <li>
                A brief description of the issue, including any steps to
                reproduce it
              </li>
            </ul>
          </div>
        </div>

        <footer
          style={{
            fontSize: "0.8rem",
            color: "#6b7280"
          }}
        >
          <p style={{ margin: 0 }}>
            We read every message and do our best to respond in a timely manner.
          </p>
        </footer>
      </section>
    </main>
  );
}


