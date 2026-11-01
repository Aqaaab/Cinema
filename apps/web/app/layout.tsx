import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "Cinema — Watch with confidence", description: "Discover films, series, and animation with transparent, territory-aware legal availability.", applicationName: "Cinema" };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
