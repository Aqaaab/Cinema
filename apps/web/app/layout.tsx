import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: {
    default: "Cinema — Watch with confidence",
    template: "%s · Cinema",
  },
  description:
    "Discover films, series, and animation with transparent, territory-aware legal availability.",
  applicationName: "Cinema",
  keywords: ["open source", "film discovery", "watchlist", "legal streaming", "anime"],
  openGraph: {
    title: "Cinema — Watch with confidence",
    description: "One library for what you want to watch, with clear sources and rights transparency.",
    type: "website",
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
