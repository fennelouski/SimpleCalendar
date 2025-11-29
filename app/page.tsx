export const metadata = {
  title: "Calendar Play — Smart, delightful calendar for iOS and tvOS",
  description:
    "Calendar Play brings a beautiful calendar with agenda, themes, holidays, weather hints, and more."
};

export default function HomePage() {
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
      <div style={{ width: "100%", maxWidth: "980px" }}>
        {/* Hero */}
        <section
          style={{
            backgroundColor: "rgba(15, 23, 42, 0.85)",
            borderRadius: "1.5rem",
            border: "1px solid rgba(148, 163, 184, 0.35)",
            boxShadow:
              "0 24px 60px rgba(15, 23, 42, 0.85), 0 0 0 1px rgba(15, 23, 42, 0.9)",
            padding: "2.75rem 2.25rem",
            textAlign: "center",
            marginBottom: "1.25rem"
          }}
        >
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
              fontSize: "2.2rem",
              lineHeight: 1.1,
              fontWeight: 800,
              color: "#e5e7eb",
              margin: 0
            }}
          >
            Calendar Play
          </h1>
          <p
            style={{
              color: "#9ca3af",
              fontSize: "1.02rem",
              lineHeight: 1.6,
              marginTop: "0.85rem",
              marginBottom: "1.25rem"
            }}
          >
            A delightful calendar with rich agenda, elegant themes, holidays, and
            helpful context like daylight and weather hints.
          </p>
          <div
            style={{
              display: "flex",
              gap: "0.75rem",
              justifyContent: "center",
              flexWrap: "wrap"
            }}
          >
            <a
              href="/support"
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "0.4rem",
                padding: "0.7rem 1.4rem",
                borderRadius: "999px",
                border: "1px solid rgba(56, 189, 248, 0.6)",
                background:
                  "linear-gradient(to right, rgba(56, 189, 248, 0.18), rgba(129, 140, 248, 0.14))",
                color: "#e0f2fe",
                fontSize: "0.95rem",
                fontWeight: 600,
                textDecoration: "none"
              }}
            >
              Get Support
              <span aria-hidden="true" style={{ fontSize: "0.9em" }}>
                →
              </span>
            </a>
            <a
              href="mailto:support@100apps.studio"
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "0.4rem",
                padding: "0.7rem 1.4rem",
                borderRadius: "999px",
                border: "1px solid rgba(148, 163, 184, 0.45)",
                color: "#e5e7eb",
                fontSize: "0.95rem",
                fontWeight: 500,
                textDecoration: "none"
              }}
            >
              Contact Us
            </a>
            <a
              href="/privacy"
              style={{
                display: "inline-flex",
                alignItems: "center",
                justifyContent: "center",
                gap: "0.35rem",
                padding: "0.7rem 1.4rem",
                borderRadius: "999px",
                border: "1px solid rgba(107, 114, 128, 0.6)",
                color: "#9ca3af",
                fontSize: "0.9rem",
                fontWeight: 500,
                textDecoration: "none"
              }}
            >
              Privacy Policy
            </a>
          </div>
        </section>

        {/* Features */}
        <section
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
            gap: "1rem"
          }}
        >
          {[
            {
              title: "Agenda & Search",
              desc:
                "Quickly browse upcoming items and find events fast with instant filtering."
            },
            {
              title: "Themes & Design",
              desc:
                "Monthly themes and a clean layout keep your calendar beautiful and legible."
            },
            {
              title: "Holidays",
              desc:
                "Curated holiday data with categories so you can show what matters to you."
            },
            {
              title: "Daylight & Weather Hints",
              desc:
                "Contextual daylight visualization and subtle weather hints to plan better."
            }
          ].map((f) => (
            <div
              key={f.title}
              style={{
                backgroundColor: "rgba(2, 6, 23, 0.55)",
                borderRadius: "1rem",
                border: "1px solid rgba(148, 163, 184, 0.25)",
                padding: "1.25rem"
              }}
            >
              <h3
                style={{
                  margin: 0,
                  marginBottom: "0.4rem",
                  color: "#e5e7eb",
                  fontSize: "1.05rem"
                }}
              >
                {f.title}
              </h3>
              <p
                style={{
                  margin: 0,
                  color: "#9ca3af",
                  fontSize: "0.95rem",
                  lineHeight: 1.55
                }}
              >
                {f.desc}
              </p>
            </div>
          ))}
        </section>

        {/* Footer */}
        <footer
          style={{
            textAlign: "center",
            marginTop: "1.5rem",
            color: "#6b7280",
            fontSize: "0.82rem"
          }}
        >
          <p style={{ margin: 0 }}>© {new Date().getFullYear()} 100 Apps Studio</p>
        </footer>
      </div>
    </main>
  );
}


