import Link from "next/link";
import { Button } from "@/components/ui/button";
import { ArrowRight } from "lucide-react";

export default function LandingPage() {
  return (
    <div className="flex flex-col items-center justify-center py-24 px-4">
      <h1 className="text-4xl font-bold tracking-tight sm:text-5xl mb-4 text-center">
        HawkTab AI
      </h1>
      <p className="text-lg text-muted-foreground max-w-xl text-center mb-8">
        Automated crosstab generation powered by AI. Upload your survey data and
        get publication-ready Excel crosstabs in minutes.
      </p>
      <Button asChild size="lg">
        <Link href="/dashboard">
          Get Started
          <ArrowRight className="ml-2 h-4 w-4" />
        </Link>
      </Button>
    </div>
  );
}
