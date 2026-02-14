import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Data & Privacy — Crosstab AI",
  description:
    "How Crosstab AI handles your data: what we collect, where it goes, and how it's protected.",
};

/* ------------------------------------------------------------------ */
/*  Section wrapper                                                   */
/* ------------------------------------------------------------------ */
function Section({
  id,
  mono,
  title,
  children,
}: {
  id?: string;
  mono: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section id={id} className="scroll-mt-20">
      <p className="font-mono text-xs text-muted-foreground uppercase tracking-widest mb-2">
        {mono}
      </p>
      <h2 className="font-serif text-2xl sm:text-3xl leading-tight mb-6">
        {title}
      </h2>
      {children}
    </section>
  );
}

/* ------------------------------------------------------------------ */
/*  Sub-section card                                                  */
/* ------------------------------------------------------------------ */
function Card({
  accent,
  heading,
  children,
}: {
  accent?: string;
  heading: string;
  children: React.ReactNode;
}) {
  return (
    <div className="bg-card border border-border rounded-lg p-6 sm:p-8 relative overflow-hidden">
      {accent && (
        <div
          className={`absolute top-0 left-0 right-0 h-0.5 ${accent}`}
        />
      )}
      <h3 className="font-serif text-xl mb-3">{heading}</h3>
      <div className="text-[15px] text-muted-foreground leading-relaxed space-y-4">
        {children}
      </div>
    </div>
  );
}

/* ------------------------------------------------------------------ */
/*  Third-party row                                                   */
/* ------------------------------------------------------------------ */
function ServiceRow({
  name,
  purpose,
  dataHandled,
  certifications,
  retention,
}: {
  name: string;
  purpose: string;
  dataHandled: string;
  certifications: string;
  retention: string;
}) {
  return (
    <tr className="border-t border-border/50">
      <td className="px-4 py-3 font-medium text-foreground whitespace-nowrap align-top">
        {name}
      </td>
      <td className="px-4 py-3 align-top">{purpose}</td>
      <td className="px-4 py-3 align-top">{dataHandled}</td>
      <td className="px-4 py-3 align-top font-mono text-xs">{certifications}</td>
      <td className="px-4 py-3 align-top">{retention}</td>
    </tr>
  );
}

/* ================================================================== */
/*  PAGE                                                              */
/* ================================================================== */
export default function DataPrivacyPage() {
  return (
    <div className="max-w-4xl mx-auto px-6 py-24 sm:py-32 space-y-20">
      {/* ----- Intro ----- */}
      <div>
        <p className="font-mono text-xs text-muted-foreground uppercase tracking-widest mb-4">
          Data & Privacy
        </p>
        <h1 className="font-serif text-4xl sm:text-5xl leading-[1.1] tracking-tight mb-6">
          Your data is yours. Here&apos;s how we treat it.
        </h1>
        <p className="text-lg text-muted-foreground max-w-2xl leading-relaxed">
          Crosstab AI processes market research data, which can include
          sensitive survey content and respondent information. We take that
          responsibility seriously. This page explains exactly what happens to
          your data at every step &mdash; no legal jargon, just the facts.
        </p>
      </div>

      {/* ---------------------------------------------------------- */}
      {/*  1. What we collect                                        */}
      {/* ---------------------------------------------------------- */}
      <Section mono="01" title="What we collect">
        <div className="grid gap-6">
          <Card accent="bg-ct-blue" heading="Files you upload">
            <p>
              When you create a project, you upload an <strong>SPSS data
              file (.sav)</strong>, a <strong>survey document</strong>{" "}
              (PDF or DOCX), and optionally a <strong>banner
              plan</strong> and <strong>message list</strong>. These files
              are the inputs to the crosstab pipeline.
            </p>
            <p>
              We never ask for or require personally identifiable
              information (PII) about survey respondents. The .sav file
              typically contains coded response data (numeric values and
              variable labels), not names, addresses, or contact details.
              That said, we recognize that some datasets may contain
              demographic fields or open-ended responses that could be
              sensitive.
            </p>
          </Card>

          <Card accent="bg-ct-violet" heading="Account information">
            <p>
              When you sign in, we collect your <strong>name</strong> and{" "}
              <strong>email address</strong> via our authentication
              provider (WorkOS). We also store your organization
              membership and role (admin, member, or external partner).
            </p>
            <p>
              We do not store passwords. Authentication is handled
              entirely by WorkOS, which supports enterprise SSO (SAML,
              Google Workspace, Okta, Azure AD, etc.).
            </p>
          </Card>

          <Card accent="bg-ct-emerald" heading="Usage analytics">
            <p>
              We use PostHog for product analytics to understand how
              people use the product &mdash; which features are used, where
              people get stuck, and what to improve. Events are tied to
              opaque internal IDs, <strong>not</strong> your email address
              or personal information.
            </p>
            <p>
              Session replays are enabled for a small percentage of
              sessions (roughly 10%) to help us debug UI issues. Replays
              capture page interactions but do not capture passwords or
              keystrokes in sensitive fields.
            </p>
          </Card>

          <Card heading="Error monitoring">
            <p>
              We use Sentry to catch and fix software bugs. Error reports
              include stack traces and breadcrumbs but are{" "}
              <strong>scrubbed of sensitive data</strong> before leaving
              your browser or our server. IP addresses, authorization
              headers, cookies, and API keys are explicitly stripped from
              all error reports.
            </p>
          </Card>
        </div>
      </Section>

      {/* ---------------------------------------------------------- */}
      {/*  2. How your data flows                                    */}
      {/* ---------------------------------------------------------- */}
      <Section mono="02" title="How your data flows through the system">
        <div className="grid gap-6">
          <Card accent="bg-ct-blue" heading="File storage (Cloudflare R2)">
            <p>
              Your uploaded files and generated outputs (Excel, R scripts,
              table definitions) are stored in{" "}
              <strong>Cloudflare R2</strong>, an S3-compatible object
              storage service. Files are organized by organization and
              project, ensuring strict tenant isolation &mdash; no other
              organization can access your files.
            </p>
            <p>
              R2 buckets are <strong>not publicly accessible</strong>.
              Downloads are served via time-limited presigned URLs (1-hour
              expiry) that require authentication. All data is encrypted
              at rest (AES-256-GCM) and in transit (TLS).
            </p>
          </Card>

          <Card accent="bg-ct-violet" heading="AI processing (Azure OpenAI)">
            <p>
              This is the most important part. Crosstab AI uses{" "}
              <strong>Azure OpenAI</strong> (Microsoft&apos;s hosted version
              of OpenAI models) to interpret your banner plan, understand
              your survey structure, and build table definitions. Here is
              exactly what is and isn&apos;t sent to the AI:
            </p>

            <div className="bg-secondary border border-border rounded-md p-4 space-y-3 mt-2">
              <div>
                <p className="text-foreground font-medium text-sm mb-1">
                  Sent to Azure OpenAI:
                </p>
                <ul className="list-disc list-inside space-y-1 text-sm">
                  <li>
                    Survey document text (question wording, answer options,
                    skip logic instructions)
                  </li>
                  <li>
                    Data map metadata (variable names, value labels,
                    variable types) &mdash; extracted from the .sav file
                  </li>
                  <li>Banner plan content (column definitions and cuts)</li>
                </ul>
              </div>
              <div>
                <p className="text-foreground font-medium text-sm mb-1">
                  Never sent to Azure OpenAI:
                </p>
                <ul className="list-disc list-inside space-y-1 text-sm">
                  <li>
                    Individual respondent data (actual survey responses,
                    case-level records)
                  </li>
                  <li>
                    The .sav file itself (processed locally via R &mdash;
                    only the extracted metadata structure reaches the AI)
                  </li>
                  <li>
                    Personally identifiable information about respondents
                  </li>
                </ul>
              </div>
            </div>

            <p>
              The actual number-crunching &mdash; computing frequencies,
              cross-tabulations, and statistical tests &mdash; happens
              entirely in <strong>R on our server</strong>, not in the AI.
              The AI generates the instructions; R executes them against
              the real data. The AI never sees the underlying response
              data.
            </p>
          </Card>

          <Card accent="bg-ct-amber" heading="What Azure OpenAI does with your data">
            <p>
              Microsoft makes the following commitments for Azure OpenAI:
            </p>
            <ul className="list-disc list-inside space-y-1.5 text-sm">
              <li>
                Your prompts and outputs are{" "}
                <strong>not used to train any AI models</strong>
              </li>
              <li>
                Your data is{" "}
                <strong>not shared with OpenAI</strong> or any third party
              </li>
              <li>
                Your data is{" "}
                <strong>not available to other customers</strong>
              </li>
              <li>
                All data is encrypted at rest (AES-256) and in transit
              </li>
              <li>
                Processing happens within Azure&apos;s infrastructure,
                completely isolated from OpenAI&apos;s consumer services
              </li>
            </ul>
            <p>
              By default, Azure may temporarily retain prompts for up to
              30 days for abuse monitoring. Enterprise customers can apply
              for Microsoft&apos;s &ldquo;Modified Abuse Monitoring&rdquo;
              program to eliminate all data retention. Azure OpenAI holds
              SOC&nbsp;2 Type&nbsp;II, ISO&nbsp;27001, HIPAA, and 100+
              additional compliance certifications.
            </p>
          </Card>

          <Card heading="Database (Convex)">
            <p>
              Project metadata, run status, and configuration are stored in{" "}
              <strong>Convex</strong>, our real-time database. Convex
              stores references to your files (storage keys), not the
              files themselves. No survey data, respondent data, or file
              contents are stored in the database.
            </p>
            <p>
              Convex is SOC&nbsp;2 Type&nbsp;II compliant, encrypts all
              data at rest (AES-256) and in transit (TLS), and isolates
              each customer database with unique credentials.
            </p>
          </Card>
        </div>
      </Section>

      {/* ---------------------------------------------------------- */}
      {/*  3. Third-party services                                   */}
      {/* ---------------------------------------------------------- */}
      <Section mono="03" title="Third-party services">
        <p className="text-[15px] text-muted-foreground leading-relaxed mb-6">
          Every external service we use has a Data Processing Agreement
          (DPA) and SOC&nbsp;2 Type&nbsp;II certification. Here&apos;s the
          complete list:
        </p>
        <div className="overflow-x-auto -mx-6 sm:mx-0">
          <div className="min-w-[700px] sm:min-w-0">
            <table className="w-full text-sm text-muted-foreground">
              <thead>
                <tr className="bg-secondary text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                  <th className="text-left px-4 py-2.5">Service</th>
                  <th className="text-left px-4 py-2.5">Purpose</th>
                  <th className="text-left px-4 py-2.5">Data handled</th>
                  <th className="text-left px-4 py-2.5">Certifications</th>
                  <th className="text-left px-4 py-2.5">Retention</th>
                </tr>
              </thead>
              <tbody>
                <ServiceRow
                  name="Azure OpenAI"
                  purpose="AI pipeline (survey interpretation, table building)"
                  dataHandled="Survey text, variable metadata, banner content"
                  certifications="SOC 2, ISO 27001, HIPAA, FedRAMP"
                  retention="Up to 30 days (abuse monitoring); opt-out available"
                />
                <ServiceRow
                  name="Cloudflare R2"
                  purpose="File storage"
                  dataHandled="Uploaded files (.sav, PDF, DOCX) and outputs (.xlsx)"
                  certifications="SOC 2, ISO 27001/27701"
                  retention="Until project deleted"
                />
                <ServiceRow
                  name="Convex"
                  purpose="Database"
                  dataHandled="Project metadata, run status, file references (no file contents)"
                  certifications="SOC 2"
                  retention="Until account deleted"
                />
                <ServiceRow
                  name="WorkOS"
                  purpose="Authentication & SSO"
                  dataHandled="Email, name, org membership"
                  certifications="SOC 2"
                  retention="Per WorkOS policy"
                />
                <ServiceRow
                  name="PostHog"
                  purpose="Product analytics"
                  dataHandled="Usage events with opaque IDs (no email/PII)"
                  certifications="SOC 2, HIPAA"
                  retention="Up to 7 years (analytics); configurable"
                />
                <ServiceRow
                  name="Sentry"
                  purpose="Error monitoring"
                  dataHandled="Error reports (scrubbed of PII, IPs, auth headers)"
                  certifications="SOC 2, ISO 27001"
                  retention="30-90 days (plan-dependent)"
                />
              </tbody>
            </table>
          </div>
        </div>
      </Section>

      {/* ---------------------------------------------------------- */}
      {/*  4. Healthcare / PHI considerations                        */}
      {/* ---------------------------------------------------------- */}
      <Section mono="04" title="Healthcare and sensitive data">
        <div className="grid gap-6">
          <Card accent="bg-ct-amber" heading="Protected Health Information (PHI)">
            <p>
              Market research studies sometimes touch healthcare topics.
              While crosstab data is typically aggregated and coded (not
              individual medical records), we recognize the sensitivity.
            </p>
            <p>
              <strong>Crosstab AI is not currently HIPAA-certified as a
              product.</strong> However, the core infrastructure services
              we depend on &mdash; Azure OpenAI, Sentry, and PostHog
              &mdash; all offer HIPAA compliance and Business Associate
              Agreements (BAAs) at their enterprise tiers.
            </p>
            <p>
              If your datasets contain information that may qualify as PHI
              under HIPAA, please contact us before uploading so we can
              discuss appropriate safeguards.
            </p>
          </Card>

          <Card heading="Respondent anonymity">
            <p>
              The pipeline is designed to work with coded survey data, not
              personally identifiable respondent information. The AI
              agents see question text and variable structure &mdash; never
              individual responses. The R computation layer processes the
              actual data locally and outputs only aggregate statistics
              (frequencies, percentages, significance tests).
            </p>
            <p>
              If your .sav file contains open-ended verbatim responses or
              other fields that could identify individuals, those fields
              pass through R for computation but are{" "}
              <strong>never sent to the AI</strong> and are{" "}
              <strong>not included in the final Excel output</strong>{" "}
              unless they are explicitly part of your table definitions.
            </p>
          </Card>
        </div>
      </Section>

      {/* ---------------------------------------------------------- */}
      {/*  5. Security                                               */}
      {/* ---------------------------------------------------------- */}
      <Section mono="05" title="Security measures">
        <div className="grid sm:grid-cols-2 gap-6">
          <Card heading="Encryption">
            <p>
              All data is encrypted at rest (AES-256) and in transit
              (TLS/HTTPS) across every service we use. R2 uses
              AES-256-GCM. Convex uses AES-256. There is no unencrypted
              data at any point in the pipeline.
            </p>
          </Card>
          <Card heading="Authentication">
            <p>
              Every API endpoint requires authentication. Sessions are
              managed by WorkOS with HTTP-only cookies. Enterprise SSO
              (SAML, OAuth) is supported. We never store passwords.
            </p>
          </Card>
          <Card heading="Authorization">
            <p>
              All resources are organization-scoped. Users can only access
              projects within their own organization. Role-based access
              control (admin, member, external partner) restricts
              sensitive operations. Cross-organization access is
              architecturally impossible.
            </p>
          </Card>
          <Card heading="Rate limiting">
            <p>
              All API endpoints are rate-limited by organization to
              prevent abuse. Pipeline-triggering operations have the most
              restrictive limits. Rate limits are enforced server-side and
              cannot be bypassed.
            </p>
          </Card>
        </div>
      </Section>

      {/* ---------------------------------------------------------- */}
      {/*  6. Data retention & deletion                              */}
      {/* ---------------------------------------------------------- */}
      <Section mono="06" title="Data retention and deletion">
        <Card accent="bg-ct-red" heading="Your right to delete">
          <p>
            You can delete any project at any time from the dashboard.
            When a project is deleted, <strong>all associated files are
            permanently removed</strong> from Cloudflare R2 &mdash;
            including uploaded inputs and all generated outputs. Project
            and run metadata are soft-deleted from the database.
          </p>
          <p>
            Temporary files used during pipeline processing are
            automatically cleaned up and do not persist after a run
            completes.
          </p>
          <p>
            If you need your entire account and all associated data
            deleted, contact us and we will process the request promptly.
          </p>
        </Card>
      </Section>

      {/* ---------------------------------------------------------- */}
      {/*  7. What we don't do                                       */}
      {/* ---------------------------------------------------------- */}
      <Section mono="07" title="What we don&rsquo;t do">
        <div className="bg-card border border-border rounded-lg p-6 sm:p-8">
          <ul className="space-y-3 text-[15px] text-muted-foreground leading-relaxed">
            <li className="flex gap-3">
              <span className="text-ct-emerald shrink-0 mt-0.5">&#10003;</span>
              <span>
                We <strong>don&apos;t sell your data</strong> or share it
                with third parties for marketing purposes.
              </span>
            </li>
            <li className="flex gap-3">
              <span className="text-ct-emerald shrink-0 mt-0.5">&#10003;</span>
              <span>
                We <strong>don&apos;t use your data to train AI
                models</strong>. Neither do our AI providers (Azure
                OpenAI).
              </span>
            </li>
            <li className="flex gap-3">
              <span className="text-ct-emerald shrink-0 mt-0.5">&#10003;</span>
              <span>
                We <strong>don&apos;t track you with third-party
                advertising pixels</strong> or retargeting scripts.
              </span>
            </li>
            <li className="flex gap-3">
              <span className="text-ct-emerald shrink-0 mt-0.5">&#10003;</span>
              <span>
                We <strong>don&apos;t store passwords</strong>.
                Authentication is fully delegated to WorkOS.
              </span>
            </li>
            <li className="flex gap-3">
              <span className="text-ct-emerald shrink-0 mt-0.5">&#10003;</span>
              <span>
                We <strong>don&apos;t send individual respondent
                data to the AI</strong>. Only survey structure and
                metadata reach the AI layer.
              </span>
            </li>
            <li className="flex gap-3">
              <span className="text-ct-emerald shrink-0 mt-0.5">&#10003;</span>
              <span>
                We <strong>don&apos;t make R2 buckets publicly
                accessible</strong>. All file access requires
                authentication and time-limited URLs.
              </span>
            </li>
          </ul>
        </div>
      </Section>

      {/* ---------------------------------------------------------- */}
      {/*  8. Contact                                                */}
      {/* ---------------------------------------------------------- */}
      <section className="text-center py-12">
        <h2 className="font-serif text-2xl sm:text-3xl mb-4">
          Questions?
        </h2>
        <p className="text-muted-foreground text-[15px] leading-relaxed max-w-lg mx-auto mb-6">
          If you have questions about how your data is handled, need to
          discuss specific compliance requirements, or want to request
          data deletion, reach out to us directly.
        </p>
        <Link
          href="/dashboard"
          className="inline-flex items-center text-sm font-medium bg-primary text-primary-foreground px-5 py-2 rounded-md hover:opacity-90 transition-opacity"
        >
          Back to Dashboard
        </Link>
      </section>

      {/* ----- Last updated ----- */}
      <div className="text-center border-t border-border pt-8">
        <p className="font-mono text-xs text-muted-foreground">
          Last updated: February 2026
        </p>
      </div>
    </div>
  );
}
