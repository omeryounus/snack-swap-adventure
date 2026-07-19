import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Snack Swap Adventure — Leaderboard",
  description: "Live leaderboard and player stats for Snack Swap Adventure",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
