// Production prompt for Banner Processor extraction
export const BANNER_EXTRACTION_PROMPT_PRODUCTION = `
You are analyzing a banner plan document to extract crosstab column specifications and notes.

EXTRACTION GOALS:
1. Identify all table structures containing column definitions (these are "banner cuts")
2. Extract column names and their filter expressions exactly as written
3. Assign statistical letters (A, B, C...) in sequence
4. Group related columns into logical banner cuts
5. Extract all notes sections exactly as written

CRITICAL GROUP SEPARATION REQUIREMENT:
EACH LOGICAL GROUP YOU IDENTIFY MUST BE A SEPARATE ENTRY IN THE BANNER CUTS ARRAY

Look for visual separators, merged headers, spacing, and logical categories:
- Specialty groups (Cards, PCPs, Nephs, Endos, etc.)
- Role groups (HCP, NP/PA, etc.) 
- Volume groups (Higher, Lower, etc.)
- Tier groups (Tier 1, Tier 2, etc.)
- Segment groups (Segment A, B, C, etc.)
- Account priority groups (Priority, Non-Priority, etc.)

Each group should contain 2-8 related columns. This separation enables proper for-loop processing in the next step.

BANNER CUT DETECTION:
- Look for tabular layouts with headers and rows
- Common headers: "Column", "Group", "Filter", "Definition"
- May contain statistical letter assignments
- Tables often grouped by specialty, demographics, tiers, etc.
- Content may span multiple pages - analyze all images together for complete context

COLUMN EXTRACTION:
- Name: The descriptive column name (e.g., "Cards", "PCPs", "HCP")
- Original: The exact filter expression as written (e.g., "S2=1", "IF HCP")
- Preserve exact syntax including typos or ambiguities

NOTES EXTRACTION:
- Look for sections with headings like "Calculations/Rows", "Main Tab Notes", etc.
- Extract text exactly as written - preserve formatting
- Common note types: calculation_rows, main_tab_notes, other

STATISTICAL LETTERS:
- Assign letters A, B, C... Z, then AA, AB, AC...
- Follow left-to-right, top-to-bottom order
- Reserve 'T' for Total column
- Each column gets unique letter

USE YOUR SCRATCHPAD TO THINK THROUGH THE GROUPINGS:
- Identify visual separators and merged headers
- Group related columns by logical category
- Ensure each group gets its own bannerCuts entry
- Show your reasoning for group boundaries

OUTPUT REQUIREMENTS:
- Multiple groups in bannerCuts array (NOT one mega-group)
- Exact JSON schema compliance
- No interpretation of business logic - pure extraction only
- Include metadata about processing context
- ALWAYS extract a separate "Total" group, even if it's just a single "Total" column — the filter expression should be "qualified respondents"

Extract all banner cut structures with proper group separation to enable downstream for-loop processing.
`;