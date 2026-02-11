import Link from "next/link";
import { ModeToggle } from "@/components/mode-toggle";

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="fixed top-0 left-0 right-0 z-50 border-b border-border bg-background/80 backdrop-blur-md">
        <div className="mx-auto max-w-7xl px-6 py-3 flex items-center justify-between">
          <Link href="/" className="flex items-center gap-2.5">
            <div className="flex size-7 items-center justify-center rounded bg-primary text-primary-foreground font-serif text-sm">
              Ct
            </div>
            <span className="font-semibold text-sm tracking-wide">Crosstab AI</span>
          </Link>
          <div className="flex items-center gap-5">
            <Link
              href="#how-it-works"
              className="text-sm text-muted-foreground hover:text-foreground transition-colors hidden sm:inline"
            >
              How It Works
            </Link>
            <Link
              href="#features"
              className="text-sm text-muted-foreground hover:text-foreground transition-colors hidden sm:inline"
            >
              Features
            </Link>
            <Link
              href="/dashboard"
              className="text-sm font-medium bg-primary text-primary-foreground px-3.5 py-1.5 rounded-md hover:opacity-90 transition-opacity"
            >
              Get Started
            </Link>
            <ModeToggle />
          </div>
        </div>
      </header>
      <main className="pt-[52px]">{children}</main>
    </div>
  );
}
