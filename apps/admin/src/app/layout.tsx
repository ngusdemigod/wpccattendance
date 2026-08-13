import type { Metadata, Viewport } from "next";
import { Urbanist } from "next/font/google";
import "./globals.css";
import "./churchmetric-theme.css";
import { AnalyticsConsent } from "@/features/observability/analytics-consent";
import { ServiceWorkerRegistration } from "@/features/pwa/service-worker-registration";

const urbanist = Urbanist({
  variable: "--font-urbanist",
  display: "swap",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "Dream Team",
  description: "Administration dashboard for the WPCC attendance app.",
  applicationName: "Dream Team",
  manifest: "/manifest.webmanifest",
  appleWebApp: { capable: true, statusBarStyle: "black-translucent", title: "Dream Team" },
  icons: { icon: "/wpcc-logo.png", apple: "/wpcc-logo.png" },
};

export const viewport: Viewport = {
  themeColor: "#123b2a",
  colorScheme: "dark light",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={urbanist.variable} suppressHydrationWarning>
      <body className="min-h-full flex flex-col">{children}<AnalyticsConsent/><ServiceWorkerRegistration/></body>
    </html>
  );
}
