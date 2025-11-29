export const metadata = {
  title: "Calendar Play – Privacy Policy",
  description:
    "Privacy policy for Calendar Play by 100 Apps Studio, explaining what data is collected and how it is used."
};

export default function PrivacyPage() {
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
      <article
        style={{
          width: "100%",
          maxWidth: "780px",
          backgroundColor: "rgba(15, 23, 42, 0.9)",
          borderRadius: "1.5rem",
          border: "1px solid rgba(148, 163, 184, 0.35)",
          boxShadow:
            "0 24px 60px rgba(15, 23, 42, 0.85), 0 0 0 1px rgba(15, 23, 42, 0.9)",
          padding: "2.5rem 2.25rem",
          color: "#e5e7eb"
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
            Calendar Play – Privacy Policy
          </h1>
        </header>

        <section
          style={{
            fontSize: "0.96rem",
            lineHeight: 1.7,
            color: "#d1d5db",
            display: "flex",
            flexDirection: "column",
            gap: "1.25rem"
          }}
        >
          <p style={{ margin: 0 }}>
            This privacy policy explains how Calendar Play (the &quot;App&quot;), developed
            by 100 Apps Studio (&quot;we&quot;, &quot;us&quot;), handles your data.
          </p>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Data We Collect
            </h2>
            <p style={{ margin: 0 }}>
              Calendar Play primarily stores your data on your device and in your
              own calendar accounts (such as iCloud or Google Calendar) as
              configured in the App. We do not collect personally identifiable
              information from you for our own servers when you simply use the App
              as a local calendar viewer.
            </p>
          </div>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Calendar and Event Data
            </h2>
            <p style={{ margin: 0 }}>
              The App may request permission to access your calendar data in order
              to display events and reminders. This data remains under the control
              of your device and calendar providers. We do not transmit your
              personal calendar contents to our own servers.
            </p>
          </div>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Third-Party Services
            </h2>
            <p style={{ margin: 0 }}>
              Calendar Play may integrate with third-party services (for example,
              calendar providers or image/weather APIs) to provide certain
              features. Any data shared with those services is governed by their
              respective privacy policies. We recommend reviewing those policies
              when you connect third-party accounts.
            </p>
          </div>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Analytics and Diagnostics
            </h2>
            <p style={{ margin: 0 }}>
              The App may use platform-provided, privacy-focused analytics and
              crash reporting (such as Apple&apos;s anonymous diagnostics) to help us
              understand performance and improve stability. This information does
              not include your calendar contents.
            </p>
          </div>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Children&apos;s Privacy
            </h2>
            <p style={{ margin: 0 }}>
              Calendar Play is not directed to children under the age of 13. We do
              not knowingly collect personal information from children.
            </p>
          </div>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Your Choices
            </h2>
            <p style={{ margin: 0 }}>
              You can control access to your calendars and other device data
              through the system privacy settings on your device. You can disable
              permissions at any time, though some features of the App may no
              longer function correctly if access is removed.
            </p>
          </div>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Changes to This Policy
            </h2>
            <p style={{ margin: 0 }}>
              We may update this privacy policy from time to time to reflect
              improvements to the App or changes in legal requirements. When we
              make material changes, we may update this page and adjust the
              &quot;last updated&quot; date.
            </p>
          </div>

          <div>
            <h2
              style={{
                fontSize: "1.05rem",
                margin: 0,
                marginBottom: "0.4rem",
                color: "#e5e7eb"
              }}
            >
              Contact
            </h2>
            <p style={{ margin: 0 }}>
              If you have any questions about this privacy policy, please contact
              us at{" "}
              <a
                href="mailto:support@100apps.studio"
                style={{ color: "#38bdf8", textDecoration: "none" }}
              >
                support@100apps.studio
              </a>
              .
            </p>
          </div>

          <p
            style={{
              margin: 0,
              marginTop: "0.5rem",
              fontSize: "0.85rem",
              color: "#9ca3af"
            }}
          >
            Last updated: {new Date().getFullYear()}
          </p>
        </section>
      </article>
    </main>
  );
}


