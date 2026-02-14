"use client";

import Link from "next/link";
import { Menu } from "lucide-react";
import { ModeToggle } from "@/components/mode-toggle";
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetTrigger,
} from "@/components/ui/sheet";

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
            {/* Desktop navigation - hidden on mobile */}
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
              href="/data-privacy"
              className="text-sm text-muted-foreground hover:text-foreground transition-colors hidden sm:inline"
            >
              Data & Privacy
            </Link>
            <Link
              href="/dashboard"
              className="text-sm font-medium bg-primary text-primary-foreground px-3.5 py-1.5 rounded-md hover:opacity-90 transition-opacity"
            >
              Log In
            </Link>
            <ModeToggle />

            {/* Mobile menu - shown only on mobile */}
            <Sheet>
              <SheetTrigger asChild>
                <button
                  className="sm:hidden p-1.5 rounded-md hover:bg-accent transition-colors"
                  aria-label="Open menu"
                >
                  <Menu className="h-5 w-5" />
                </button>
              </SheetTrigger>
              <SheetContent side="right" className="w-3/4 sm:max-w-sm">
                <nav className="flex flex-col gap-6 mt-8">
                  <SheetClose asChild>
                    <Link
                      href="#how-it-works"
                      className="text-base text-muted-foreground hover:text-foreground transition-colors"
                    >
                      How It Works
                    </Link>
                  </SheetClose>
                  <SheetClose asChild>
                    <Link
                      href="#features"
                      className="text-base text-muted-foreground hover:text-foreground transition-colors"
                    >
                      Features
                    </Link>
                  </SheetClose>
                  <SheetClose asChild>
                    <Link
                      href="/data-privacy"
                      className="text-base text-muted-foreground hover:text-foreground transition-colors"
                    >
                      Data & Privacy
                    </Link>
                  </SheetClose>
                  <SheetClose asChild>
                    <Link
                      href="/dashboard"
                      className="text-base font-medium text-foreground"
                    >
                      Log In
                    </Link>
                  </SheetClose>
                </nav>
              </SheetContent>
            </Sheet>
          </div>
        </div>
      </header>
      <main className="pt-[52px]">{children}</main>
    </div>
  );
}
