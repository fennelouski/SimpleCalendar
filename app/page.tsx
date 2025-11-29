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
      <section
        style={{
          width: "100%",
          maxWidth: "640px",
          backgroundColor: "rgba(15, 23, 42, 0.85)",
          borderRadius: "1.5rem",
          border: "1px solid rgba(148, 163, 184, 0.35)",
          boxShadow:
            "0 24px 60px rgba(15, 23, 42, 0.85), 0 0 0 1px rgba(15, 23, 42, 0.9)",
          padding: "2.5rem 2.25rem",
          textAlign: "center"
        }}
      >
        <h1
          style={{
            fontSize: "2rem",
            lineHeight: 1.1,
            fontWeight: 700,
            color: "#e5e7eb",
            marginBottom: "0.75rem"
          }}
        >
          Calendar Play
        </h1>
        <p
          style={{
            color: "#9ca3af",
            fontSize: "0.98rem",
            lineHeight: 1.6,
            marginBottom: "1.5rem"
          }}
        >
          This is the support site for the Calendar Play app by 100 Apps Studio.
        </p>
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
            fontWeight: 500,
            textDecoration: "none"
          }}
        >
          Go to Support
          <span aria-hidden="true" style={{ fontSize: "0.9em" }}>
            →
          </span>
        </a>
      </section>
    </main>
  );
}


