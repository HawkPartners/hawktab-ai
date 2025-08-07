// Production prompt for Banner Processor extraction
export const BANNER_EXTRACTION_PROMPT_PRODUCTION = `
You are analyzing a banner plan document to extract crosstab column specifications and notes.

EXTRACTION GOALS:
1. Identify all table structures containing column definitions (these are "banner cuts")
2. Extract column names and their filter expressions exactly as written
3. Assign statistical letters (A, B, C...) in sequence
4. Group related columns into logical banner cuts
5. Extract all notes sections exactly as written

BANNER CUT DETECTION:
- Look for tabular layouts with headers and rows
- Common headers: "Column", "Group", "Filter", "Definition"
- May contain statistical letter assignments
- Tables often grouped by specialty, demographics, tiers, etc.

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

OUTPUT REQUIREMENTS:
- Exact JSON schema compliance
- No interpretation of business logic - pure extraction only
- Include metadata about processing context

Extract all banner cut structures, column names, filter expressions, assign statistical letters in sequence, and extract all notes sections exactly as written.
`;