# Crosstab AI Design System

## Brand

- **Name**: Crosstab AI (lowercase 't')
- **Logo Mark**: "Ct" in Instrument Serif on a solid primary background
- **Tagline**: "Intelligent crosstab generation for research teams"
- **No external branding** — Hawk Partners is not shown in the UI

## Typography

Three fonts, each with a distinct role:

| Font | Tailwind Class | Role | Examples |
|------|---------------|------|----------|
| **Instrument Serif** | `font-serif` | Display/headlines | Section titles, hero text, card headers |
| **Outfit** | `font-sans` (default) | Body/UI | Paragraphs, buttons, labels, navigation |
| **JetBrains Mono** | `font-mono` | Data values, code | Percentages, sample sizes, R expressions, file types, status labels |

Instrument Serif is used at **regular weight only** (no italic). It provides editorial gravitas that distinguishes the product from typical SaaS tools.

## Color System

### Philosophy

Mostly monochrome. Color is used surgically and always carries semantic meaning. It is never decorative.

### Core Palette

Defined as CSS custom properties in `globals.css`, mapped to Tailwind via `@theme inline`.

**Surfaces (dark mode primary)**:
- `--background`: #0a0b0f (near-black with blue undertone)
- `--card`: #1a1b24 (elevated surfaces)
- `--muted`: #22232e (secondary surfaces)
- `--border`: #1e2030 (subtle structure)

**Text**:
- `--foreground`: #eaedf3 (primary text, off-white)
- `--muted-foreground`: #8b8fa4 (secondary text)

### Semantic Accent Colors

Each accent color has a full-strength version and a dim version for backgrounds.

| Token | Dark | Light | Semantic Meaning |
|-------|------|-------|-----------------|
| `ct-emerald` / `ct-emerald-dim` | #34d399 / 12% | #059669 / 8% | Success, complete, approved, sig-test markers |
| `ct-amber` / `ct-amber-dim` | #fbbf24 / 12% | #d97706 / 8% | Review required, warning, attention needed |
| `ct-blue` / `ct-blue-dim` | #60a5fa / 12% | #2563eb / 8% | Active, in progress, processing, informational |
| `ct-red` / `ct-red-dim` | #f87171 / 12% | #dc2626 / 8% | Error, destructive actions, failures |
| `ct-violet` / `ct-violet-dim` | #a78bfa / 12% | #7c3aed / 8% | AI activity, alternatives, agent-related |

### Usage in Tailwind

```jsx
// Status text
<span className="text-ct-emerald">Success</span>

// Dim background for status contexts
<div className="bg-ct-amber-dim text-ct-amber">Review Required</div>

// Border accents
<div className="border-ct-violet/20">AI reasoning panel</div>
```

## Design Principles

### 1. Data-Aware

The UI should feel native to tabular data and statistical output.

- Monospace (`font-mono`) for all data values, R expressions, and file types
- Subtle dot-grid background textures (using `radial-gradient`) evoke graph paper
- Table-like layouts and clean alignment
- Significance test markers use `<sup>` with `text-ct-emerald`

### 2. Intelligence, Not Automation

The product differentiator is understanding, not speed. Copy and visuals should emphasize:

- "Crosstabs that understand your research" (not "fast crosstabs")
- The hybrid AI + deterministic approach (show both, explain why)
- "Data you can trust" — validation at every step
- "Intelligence used intentionally" — AI only where judgment is needed

### 3. Depth Through Restraint

- Monochrome as the base, with color for meaning
- No decorative gradients or shadows
- Subtle borders (`border-border`) rather than heavy elevation
- Cards use thin accent lines (2px top border) to categorize without overwhelming

### 4. Typography-Forward

Hierarchy is created through font family, weight, and size — not color or decoration.

- `font-serif text-4xl` for section headers
- `font-sans text-base font-semibold` for card titles
- `font-mono text-xs uppercase tracking-wider` for category labels
- Step numbers use `font-mono text-xs text-muted-foreground`

## Component Patterns

### Status Badges

```jsx
<Badge className="bg-ct-emerald-dim text-ct-emerald">Success</Badge>
<Badge className="bg-ct-amber-dim text-ct-amber">Review Required</Badge>
<Badge className="bg-ct-blue-dim text-ct-blue">In Progress</Badge>
<Badge className="bg-ct-red-dim text-ct-red">Error</Badge>
```

### Feature Cards

Cards with a thin top accent line for categorization:

```jsx
<div className="bg-card border border-border rounded-lg p-6 relative overflow-hidden">
  <div className="absolute top-0 left-0 right-0 h-0.5 bg-ct-violet" />
  <h3>Card Title</h3>
  <p className="text-sm text-muted-foreground">Description</p>
  <span className="font-mono text-[10px] text-muted-foreground mt-3 px-2 py-0.5 bg-secondary rounded">
    Tag label
  </span>
</div>
```

### Review Cards (HITL)

Left accent border for flagged items:

```jsx
<div className="bg-card border border-border border-l-3 border-l-ct-amber rounded-lg p-4">
  {/* Confidence bar, comparison, action buttons */}
</div>
```

### File Type Chips

```jsx
<span className="font-mono text-[11px] px-2 py-0.5 bg-secondary border border-border rounded">
  .sav
</span>
```

### Dot Grid Background

Used on hero sections and pipeline diagrams for subtle texture:

```jsx
<div style={{
  backgroundImage: "radial-gradient(circle, var(--border) 1px, transparent 1px)",
  backgroundSize: "24px 24px"
}}>
```

## Tone of Voice

- **Calm and confident.** Not punchy, not salesy. Let the product speak.
- **Benefit-focused.** "Faster time to insights" over "AI-powered automation"
- **Modest.** "Hours" not "days". No inflated claims.
- **Respectful of expertise.** Users are domain experts, not developers.
- **Don't reveal the secret sauce.** Talk about the hybrid approach, not specific agent names.

### Do say:
- "Crosstabs that understand your research"
- "Upload your files. Download when ready."
- "Intelligence used intentionally"
- "Data you can trust"
- "Your expertise stays in the process"

### Don't say:
- "Stop outsourcing your crosstabs"
- "Six AI agents"
- "95% accuracy"
- "AI-powered" (overused, says nothing)
- "Revolutionary" / "game-changing"
