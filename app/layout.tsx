export const metadata = {
  title: "Calendar Play",
  description:
    "Calendar Play by 100 Apps Studio — a delightful calendar with smart views and helpful details."
};

export default function RootLayout({
  children
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body
        style={{
          margin: 0,
          fontFamily:
            "-apple-system, BlinkMacSystemFont, system-ui, -system-ui, sans-serif",
          background:
            "radial-gradient(circle at top, #0f172a 0, #020617 40%, #000 100%)",
          color: "#e5e7eb",
          minHeight: "100vh"
        }}
      >
        {children}
      </body>
    </html>
  );
}


