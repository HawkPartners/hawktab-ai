import Link from "next/link";
import { ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function LandingPage() {
  return (
    <>
      {/* ============ HERO ============ */}
      <section className="relative min-h-[90vh] flex flex-col justify-center px-6 py-24 overflow-hidden"
        style={{ backgroundImage: "radial-gradient(circle, var(--border) 1px, transparent 1px)", backgroundSize: "24px 24px" }}>
        <div className="max-w-3xl mx-auto text-center relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 bg-secondary border border-border rounded-full text-xs text-muted-foreground font-medium tracking-wider uppercase mb-8">
            <span className="size-1.5 rounded-full bg-ct-emerald animate-pulse" />
            Now in production
          </div>

          <h1 className="font-serif text-4xl sm:text-5xl lg:text-6xl leading-[1.1] tracking-tight mb-6">
            Crosstabs that understand your research.
          </h1>

          <p className="text-lg text-muted-foreground max-w-xl mx-auto mb-8 leading-relaxed">
            Crosstab AI replaces hours of manual crosstab production with an intelligent pipeline.
            Upload your files, review the AI&apos;s work as needed, and download client-ready Excel.
          </p>

          <div className="flex gap-4 justify-center flex-wrap">
            <Button asChild size="lg">
              <Link href="/dashboard">
                Upload Your First Dataset
                <ArrowRight className="ml-2 h-4 w-4" />
              </Link>
            </Button>
            <Button variant="outline" size="lg" asChild>
              <Link href="#how-it-works">
                See How It Works
              </Link>
            </Button>
          </div>

          {/* Crosstab Preview Table */}
          <div className="mt-16 max-w-2xl mx-auto">
            <div className="bg-card border border-border rounded-lg overflow-hidden text-left">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-secondary">
                    <th className="text-left px-4 py-2.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground" style={{ width: "35%" }} />
                    <th className="text-left px-3 py-2.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Total</th>
                    <th className="text-left px-3 py-2.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Male</th>
                    <th className="text-left px-3 py-2.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Female</th>
                    <th className="text-left px-3 py-2.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">18-34</th>
                    <th className="text-left px-3 py-2.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">35-54</th>
                    <th className="text-left px-3 py-2.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">55+</th>
                  </tr>
                </thead>
                <tbody className="text-muted-foreground">
                  <tr className="border-t border-border">
                    <td className="px-4 py-2.5">Base: All respondents</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">n=402</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">n=198</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">n=204</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">n=134</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">n=156</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">n=112</td>
                  </tr>
                  <tr className="border-t border-border/50">
                    <td className="px-4 py-2.5">Very satisfied (T2B)</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">62%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">58%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">66%<sup className="text-ct-emerald ml-0.5 text-[9px]">B</sup></td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">71%<sup className="text-ct-emerald ml-0.5 text-[9px]">EF</sup></td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">60%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">53%</td>
                  </tr>
                  <tr className="border-t border-border/50">
                    <td className="px-4 py-2.5">Somewhat satisfied</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">24%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">27%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">21%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">19%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">26%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">28%</td>
                  </tr>
                  <tr className="border-t border-border/50">
                    <td className="px-4 py-2.5">Not at all satisfied (B2B)</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">14%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">15%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">13%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">10%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">14%</td>
                    <td className="px-3 py-2.5 font-mono text-xs text-foreground font-medium">19%<sup className="text-ct-emerald ml-0.5 text-[9px]">D</sup></td>
                  </tr>
                </tbody>
              </table>
              <div className="text-center px-4 py-2.5 text-xs text-muted-foreground font-mono border-t border-border bg-secondary">
                Statistical testing at 95% confidence &middot; Column letters denote significant differences
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ============ HOW IT WORKS ============ */}
      <section id="how-it-works" className="py-24 px-6 border-t border-border">
        <div className="max-w-5xl mx-auto">
          <p className="font-mono text-xs text-muted-foreground uppercase tracking-widest mb-4">How It Works</p>
          <h2 className="font-serif text-3xl sm:text-4xl leading-tight mb-4">Upload your files. Download when ready.</h2>
          <p className="text-lg text-muted-foreground max-w-xl leading-relaxed mb-12">
            You bring the data and the spec. Crosstab AI handles everything in between.
          </p>

          {/* Three Steps */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors">
              <span className="font-mono text-xs text-muted-foreground">01</span>
              <h3 className="font-serif text-2xl mt-3 mb-3">Upload</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                Drop your SPSS data file, banner plan, and optional survey document. The system validates everything before it begins.
              </p>
              <div className="flex gap-2 mt-5 flex-wrap">
                <span className="font-mono text-[11px] px-2 py-0.5 bg-secondary border border-border rounded">.sav</span>
                <span className="font-mono text-[11px] px-2 py-0.5 bg-secondary border border-border rounded">.pdf</span>
                <span className="font-mono text-[11px] px-2 py-0.5 bg-secondary border border-border rounded">.docx</span>
              </div>
            </div>
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors">
              <span className="font-mono text-xs text-muted-foreground">02</span>
              <h3 className="font-serif text-2xl mt-3 mb-3">Process</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                The pipeline reads your data, interprets your spec, builds tables, applies filters, and validates every expression &mdash; checking in with you only when it needs to.
              </p>
            </div>
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors">
              <span className="font-mono text-xs text-muted-foreground">03</span>
              <h3 className="font-serif text-2xl mt-3 mb-3">Download</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                Client-ready Excel with statistical testing, proper NET rows, and formatting your clients expect. Ready to deliver.
              </p>
              <div className="flex gap-2 mt-5 flex-wrap">
                <span className="font-mono text-[11px] px-2 py-0.5 bg-secondary border border-border rounded">.xlsx</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ============ FEATURES ============ */}
      <section id="features" className="py-24 px-6 border-t border-border">
        <div className="max-w-5xl mx-auto">
          <p className="font-mono text-xs text-muted-foreground uppercase tracking-widest mb-4">Why It&apos;s Different</p>
          <h2 className="font-serif text-3xl sm:text-4xl leading-tight mb-4">More than automatic. Intentionally intelligent.</h2>
          <p className="text-lg text-muted-foreground max-w-xl leading-relaxed mb-12">
            Other tools output tables. Crosstab AI understands your project, your data, and how you want your research delivered.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-0.5 bg-ct-violet" />
              <h3 className="font-serif text-xl mb-3">Finds the right cuts</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                Reads your banner plan and matches each cut to the actual variables in your data. Validates every expression before anything runs.
              </p>
            </div>
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-0.5 bg-ct-emerald" />
              <h3 className="font-serif text-xl mb-3">Builds the right tables</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                Adds NET rows, Top 2 Box, Bottom 2 Box. Fixes labels to match the survey wording. Splits tables when they need splitting.
              </p>
            </div>
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-0.5 bg-ct-amber" />
              <h3 className="font-serif text-xl mb-3">Respects your survey logic</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                Reads skip logic and filter rules from the survey document. Only the right respondents appear in the right tables.
              </p>
            </div>
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-0.5 bg-ct-blue" />
              <h3 className="font-serif text-xl mb-3">Handles complex data</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                Looped data, stacked structures, weighted samples. The system detects these automatically and handles them correctly.
              </p>
            </div>
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-0.5 bg-ct-red" />
              <h3 className="font-serif text-xl mb-3">Data you can trust</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                Every expression is validated against the real data before execution. Hallucinations are caught and corrected. The pipeline can never make up a number.
              </p>
            </div>
            <div className="bg-card border border-border rounded-lg p-8 hover:border-ring transition-colors relative overflow-hidden">
              <div className="absolute top-0 left-0 right-0 h-0.5 bg-muted-foreground" />
              <h3 className="font-serif text-xl mb-3">Human in the loop</h3>
              <p className="text-base text-muted-foreground leading-relaxed">
                When the system isn&apos;t sure, it asks. You review flagged items, provide corrections, and the pipeline continues. Your expertise stays in the process.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ============ CTA ============ */}
      <section className="py-32 px-6 text-center relative"
        style={{ backgroundImage: "radial-gradient(circle, var(--border) 1px, transparent 1px)", backgroundSize: "24px 24px" }}>
        <h2 className="font-serif text-4xl sm:text-5xl leading-tight mb-4 relative">Faster time to insights.</h2>
        <p className="text-lg text-muted-foreground mb-8 relative">
          Answer your clients&apos; questions sooner. Understand your data better. Spend your time on the analysis, not the tables.
        </p>
        <Button asChild size="lg" className="relative">
          <Link href="/dashboard">
            Upload Your First Dataset
            <ArrowRight className="ml-2 h-4 w-4" />
          </Link>
        </Button>
      </section>

      {/* ============ FOOTER ============ */}
      <footer className="border-t border-border text-center py-12 px-6">
        <div className="flex items-center justify-center gap-2.5 mb-3">
          <div className="flex size-6 items-center justify-center rounded bg-primary text-primary-foreground font-serif text-xs">
            Ct
          </div>
          <span className="font-semibold text-sm">Crosstab AI</span>
        </div>
        <p className="text-xs text-muted-foreground">Intelligent crosstab generation for research teams</p>
      </footer>
    </>
  );
}
