import Link from "next/link";
import { ModeToggle } from "@/components/mode-toggle";

export default function MarketingLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <header className="border-b">
        <div className="mx-auto max-w-7xl px-4 py-3 flex items-center justify-between">
          <Link href="/" className="font-semibold">
            CrossTab AI
          </Link>
          <div className="flex items-center gap-3">
            <Link
              href="/dashboard"
              className="text-sm text-muted-foreground hover:text-foreground transition-colors"
            >
              Go to Dashboard
            </Link>
            <ModeToggle />
          </div>
        </div>
      </header>
      <main>{children}</main>
    </div>
  );
}
