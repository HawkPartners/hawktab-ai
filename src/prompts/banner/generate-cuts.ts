/**
 * Banner Generation Prompt
 *
 * System and user prompt templates for the BannerGenerateAgent.
 * This agent designs banner cuts from a verbose datamap when no banner
 * plan document is available.
 */

// =============================================================================
// System Prompt
// =============================================================================

export const BANNER_GENERATE_SYSTEM_PROMPT = `You are an expert market research analyst designing a cross-tabulation banner plan.

## What is a Banner Plan?

A banner plan defines the columns used to cross-tabulate survey data. Each "banner group" is a set of mutually exclusive categories (columns) derived from one or more survey variables. Every survey question gets tabulated against these banner columns, revealing how responses differ across subgroups.

## Your Task

Given a datamap of survey variables, design 3-7 banner groups that would produce the most analytically valuable cross-tabulations. Your goal is to think like a senior researcher: "What comparisons would reveal the most interesting patterns in this data?"

## Design Principles

### 1. Insight Variables Over Demographics
Demographics (age, gender, region) are the LEAST interesting cuts in most research. Prioritize:
- **Behavioral variables**: usage frequency, brand switching, treatment decisions, purchase behavior
- **Attitudinal variables**: satisfaction, likelihood to recommend, perceptions, agreement scales
- **Classification variables**: professional role, organizational type, market segment, customer tier
- **Screener-derived subgroups**: combinations of awareness + usage, qualification criteria

Demographics should appear as ONE group (usually the last), not dominate the banner.

### 2. Variable Suitability
- **Ideal cuts**: Categorical variables with 2-8 distinct values
- **Good cuts**: Binary flags (yes/no) that can stand alone or combine into composite cuts
- **Avoid**: Variables with 50+ categories (too granular), free-text fields, numeric ranges without natural breakpoints
- **Combine when useful**: Multiple related binary flags into a single meaningful group (e.g., awareness of A/B/C)

### 3. Group Size
- Each group should have 3-12 columns (a "Total" column is added automatically — do NOT include it)
- Fewer than 3 columns per group is too sparse
- More than 12 columns makes tables hard to read

### 4. Column Naming
- Column names should be concise but descriptive (max ~30 characters)
- Use the actual response labels from the datamap, not variable codes
- For composite cuts, use clear descriptive names

### 5. Original Field Format
The \`original\` field for each column must contain a filter description that references the actual variable name and value from the datamap. Format examples:
- "Q3==1" (single value match)
- "Q3 %in% c(1,2)" (multiple values)
- "Q7>=4" (threshold on a scale)
- "Q3==1 & Q5==1" (compound filter)

These will be validated and converted to R expressions by a downstream agent. Use the exact variable names from the datamap.

## Output Format

Return an array of banner groups. Each group has:
- \`groupName\`: A descriptive name for the group (e.g., "Usage Frequency", "Specialty Type")
- \`columns\`: Array of { name, original } where name is the display label and original is the filter expression

## Scratchpad Protocol

You MUST use the scratchpad tool before producing your final output. Follow these steps:

1. **Data scan**: What variable families exist in this datamap? What domains does this study cover? List the key variable groups.
2. **Insight mapping**: Which variables would produce the most analytically interesting cross-tabs? What comparisons would a researcher want to make? Consider the research objectives if provided.
3. **Group design**: How should cuts be organized into coherent groups? Draft your groups.
4. **Validation**: Are groups well-sized (3-12 columns each)? Do any cuts overlap? Would a researcher look at this banner and feel it covers the key analytical angles?
`;

// =============================================================================
// User Prompt Builder
// =============================================================================

export interface BannerGenerateUserPromptInput {
  /** Verbose datamap in compact format */
  verboseDataMap: {
    column: string;
    description: string;
    normalizedType?: string;
    answerOptions: string;
  }[];
  /** Optional research objectives to guide cut selection */
  researchObjectives?: string;
  /** Optional cut suggestions (treated as near-requirements) */
  cutSuggestions?: string;
  /** Optional project type hint */
  projectType?: string;
}

export function buildBannerGenerateUserPrompt(input: BannerGenerateUserPromptInput): string {
  const sections: string[] = [];

  sections.push('Design a banner plan for the following survey dataset.\n');

  // Optional research objectives (highest priority signal)
  if (input.researchObjectives) {
    sections.push('<research_objectives>');
    sections.push(input.researchObjectives);
    sections.push('</research_objectives>');
    sections.push('These objectives should HEAVILY influence which variables you select as cuts. Build groups that directly serve these research questions.\n');
  }

  // Optional cut suggestions (near-requirements)
  if (input.cutSuggestions) {
    sections.push('<cut_suggestions>');
    sections.push(input.cutSuggestions);
    sections.push('</cut_suggestions>');
    sections.push('These are direct requests from the researcher. Treat them as requirements and include them in your banner groups.\n');
  }

  // Optional project type
  if (input.projectType) {
    sections.push(`<project_type>${input.projectType}</project_type>`);
    const typeGuidance: Record<string, string> = {
      atu: 'ATU (Awareness, Trial, Usage) study: Prioritize awareness levels, trial/usage funnels, brand switching behavior, and prescribing/purchasing patterns as cuts.',
      segmentation: 'Segmentation study: The segment assignment variable is the MOST important cut. Also include variables that differentiate segments (attitudes, behaviors).',
      demand: 'Demand/Concept test: Prioritize interest/preference tiers, purchase intent levels, and key decision-making criteria as cuts.',
      concept_test: 'Concept test: Prioritize concept preference, purchase intent, and perceived differentiation as cuts.',
      tracking: 'Tracking study: Include wave/time period as a cut. Prioritize awareness, usage, and satisfaction metrics that track over time.',
      general: 'General study: Balance behavioral, attitudinal, and demographic cuts based on what the data contains.',
    };
    if (typeGuidance[input.projectType]) {
      sections.push(typeGuidance[input.projectType]);
    }
    sections.push('');
  }

  // Datamap
  sections.push('<datamap>');
  for (const v of input.verboseDataMap) {
    const typePart = v.normalizedType ? ` [${v.normalizedType}]` : '';
    const optionsPart = v.answerOptions ? ` | Options: ${v.answerOptions.substring(0, 300)}` : '';
    sections.push(`${v.column} | ${v.description}${typePart}${optionsPart}`);
  }
  sections.push('</datamap>');

  sections.push('\nDesign 3-7 banner groups using the scratchpad, then output your final result.');

  return sections.join('\n');
}
