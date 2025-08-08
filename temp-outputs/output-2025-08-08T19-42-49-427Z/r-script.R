# HawkTab AI — Generated R Script
# Session: output-2025-08-08T19-42-49-427Z
# Generated: 2025-08-08T19:47:44.041Z

library(haven)
data <- read_sav('temp-outputs/output-2025-08-08T19-42-49-427Z/dataFile.sav')


# ===== Group: Specialty =====
# Cards | conf=0.980 | Direct mapping: S2 (primary specialty) code 1 = Cardiologist and S2a (office type) code 1 = Cardiologist. Converted to R syntax with '==' and '&'.
(S2 == 1 & S2a == 1)
# PCPs | conf=0.970 | Direct mapping: S2 code 2 = Internal Medicine/General Practitioner/Primary Care/Family Practice aligns with PCPs. Converted to R syntax with '=='.
S2 == 2
# Nephs | conf=0.970 | Direct mapping: S2 code 3 = Nephrologist. Converted to R syntax with '=='.
S2 == 3
# Endos | conf=0.970 | Direct mapping: S2 code 4 = Endocrinologist. Converted to R syntax with '=='.
S2 == 4
# Lipids | conf=0.970 | Direct mapping: S2 code 5 = Lipidologist. Converted to R syntax with '=='.
S2 == 5

# ===== Group: Role =====
# HCP | conf=0.950 | Mapped to S2b (primary role). S2b value 1 corresponds to Physician, interpreted as HCP in this context. Chose S2b over other specialty variables for clarity and direct role mapping.
S2b == 1
# NP/PA | conf=0.950 | Mapped to S2b (primary role). Values 2 and 3 correspond to Nurse Practitioner and Physician’s Assistant, respectively, matching NP/PA grouping. Direct mapping with clear answer options.
S2b %in% c(2,3)

# ===== Group: Volume of Adult ASCVD Patients =====
# Higher | conf=0.600 | Placeholder expression; no direct mapping exists. Identified S10 and S11 as potential volume variables; selected S11 (adult patients with hypercholesterolemia and established CVD) to represent ASCVD patient volume based on group context. Applied median split for Higher group per placeholder guidelines.
S11 >= median(S11, na.rm = TRUE)
# Lower | conf=0.600 | Placeholder expression; no direct mapping exists. Identified S10 and S11 as potential volume variables; selected S11 to represent ASCVD patient volume. Applied median split for Lower group per placeholder guidelines.
S11 < median(S11, na.rm = TRUE)

# ===== Group: Tiers =====
# Tier 1 | conf=0.980 | Direct mapping: qLIST_TIER has value 1 corresponding to 'TIER 1' in the data map answer options. Unambiguous match.
qLIST_TIER == 1
# Tier 2 | conf=0.980 | Direct mapping: qLIST_TIER has value 2 corresponding to 'TIER 2' in the data map answer options. Unambiguous match.
qLIST_TIER == 2
# Tier 3 | conf=0.980 | Direct mapping: qLIST_TIER has value 3 corresponding to 'TIER 3' in the data map answer options. Unambiguous match.
qLIST_TIER == 3
# Tier 4 | conf=0.980 | Direct mapping: qLIST_TIER has value 4 corresponding to 'TIER 4' in the data map answer options. Unambiguous match.
qLIST_TIER == 4

# ===== Group: Segments =====
# Segment A | conf=0.850 | Variable 'Segment' found in data map; no answer options defined, so assuming the response is stored as the literal label 'Segment A'. Confidence reduced due to unknown coding of values.
Segment == "Segment A"
# Segment B | conf=0.850 | Variable 'Segment' found in data map; no answer options defined, so assuming the response is stored as the literal label 'Segment B'. Confidence reduced due to unknown coding of values.
Segment == "Segment B"
# Segment C | conf=0.850 | Variable 'Segment' found in data map; no answer options defined, so assuming the response is stored as the literal label 'Segment C'. Confidence reduced due to unknown coding of values.
Segment == "Segment C"
# Segment D | conf=0.850 | Variable 'Segment' found in data map; no answer options defined, so assuming the response is stored as the literal label 'Segment D'. Confidence reduced due to unknown coding of values.
Segment == "Segment D"

# ===== Group: Priority Accounts =====
# Priority Account | conf=0.980 | Mapped to qLIST_PRIORITY_ACCOUNT (LIST PRIORITY ACCOUNT) where 1=PRIORITY. Direct variable match with clear, unambiguous mapping.
qLIST_PRIORITY_ACCOUNT == 1
# Non-Priority Account | conf=0.980 | Mapped to qLIST_PRIORITY_ACCOUNT (LIST PRIORITY ACCOUNT) where 2=NOT PRIORITY. Direct variable match with clear, unambiguous mapping.
qLIST_PRIORITY_ACCOUNT == 2

# ===== Group: Total =====
# Total | conf=0.980 | Mapped 'qualified respondents' to the data map variable 'status' with value 3 labeled 'Qualified'. Direct exact match → high confidence.
status == 3