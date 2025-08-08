# HawkTab AI — Generated R Script
# Session: output-2025-08-08T14-53-39-903Z
# Generated: 2025-08-08T14:58:38.778Z

library(haven)
data <- read_sav('temp-outputs/output-2025-08-08T14-53-39-903Z/dataFile.sav')


# ===== Group: Specialty =====
# Cards | conf=0.900 | Both S2 and S2a are direct matches in the data map. S2=1 corresponds to Cardiologist, and S2a=1 corresponds to working in a Cardiologist office. Combined with AND logic, the R syntax is straightforward.
(S2 == 1 & S2a == 1)
# PCPs | conf=0.970 | S2 is a direct match; value 2 corresponds to Internal Medicine / General Practitioner / Primary Care / Family Practice, which aligns with PCPs. Simple equality mapping.
S2 == 2
# Nephs | conf=0.970 | S2 is a direct match; value 3 corresponds to Nephrologist (Nephs). Direct and unambiguous.
S2 == 3
# Endos | conf=0.970 | S2 is a direct match; value 4 corresponds to Endocrinologist (Endos). Direct and unambiguous.
S2 == 4
# Lipids | conf=0.970 | S2 is a direct match; value 5 corresponds to Lipidologist (Lipids). Direct and unambiguous.
S2 == 5

# ===== Group: Role =====
# HCP | conf=0.950 | Mapped to S2b (primary role) where 1 = Physician. 'HCP' is interpreted as physicians given the separate NP/PA category. Direct variable match with clear codes.
S2b == 1
# NP/PA | conf=0.950 | Mapped to S2b (primary role) where 2 = Nurse Practitioner and 3 = Physician’s Assistant. Direct mapping of NP/PA to these codes.
S2b %in% c(2,3)

# ===== Group: Volume of Adult ASCVD Patients =====
# Higher | conf=0.350 | Original expression is a placeholder with no cutoff specified. Variable 'S11' corresponds to the number of adult patients with confirmed hypercholesterolemia and established CVD (i.e., adult ASCVD volume). Using median(S11) as a provisional cutoff for 'Higher'. Manual review needed to define the specific cutoff.
S11 > median(S11, na.rm=TRUE)
# Lower | conf=0.350 | Original expression is a placeholder with no cutoff specified. Variable 'S11' corresponds to the number of adult patients with confirmed hypercholesterolemia and established CVD (i.e., adult ASCVD volume). Using median(S11) as a provisional cutoff for 'Lower'. Manual review needed to define the specific cutoff.
S11 <= median(S11, na.rm=TRUE)

# ===== Group: Tiers =====
# Tier 1 | conf=0.980 | Mapped 'Tier 1 from list' to qLIST_TIER based on data map: qLIST_TIER answer option 1 = TIER 1. Direct, unambiguous mapping.
qLIST_TIER == 1
# Tier 2 | conf=0.980 | Mapped 'Tier 2 from list' to qLIST_TIER based on data map: qLIST_TIER answer option 2 = TIER 2. Direct, unambiguous mapping.
qLIST_TIER == 2
# Tier 3 | conf=0.980 | Mapped 'Tier 3 from list' to qLIST_TIER based on data map: qLIST_TIER answer option 3 = TIER 3. Direct, unambiguous mapping.
qLIST_TIER == 3
# Tier 4 | conf=0.980 | Mapped 'Tier 4 from list' to qLIST_TIER based on data map: qLIST_TIER answer option 4 = TIER 4. Direct, unambiguous mapping.
qLIST_TIER == 4

# ===== Group: Segments =====
# Segment A | conf=0.650 | Mapped to variable 'Segment' found in data map. No answer options defined, so assumed categories are coded as strings 'A', 'B', 'C', 'D'. Confidence reduced due to this assumption and possibility of numeric coding.
Segment == "A"
# Segment B | conf=0.650 | Mapped to variable 'Segment' found in data map. No answer options defined, so assumed categories are coded as strings 'A', 'B', 'C', 'D'. Confidence reduced due to this assumption and possibility of numeric coding.
Segment == "B"
# Segment C | conf=0.650 | Mapped to variable 'Segment' found in data map. No answer options defined, so assumed categories are coded as strings 'A', 'B', 'C', 'D'. Confidence reduced due to this assumption and possibility of numeric coding.
Segment == "C"
# Segment D | conf=0.650 | Mapped to variable 'Segment' found in data map. No answer options defined, so assumed categories are coded as strings 'A', 'B', 'C', 'D'. Confidence reduced due to this assumption and possibility of numeric coding.
Segment == "D"

# ===== Group: Priority Accounts =====
# Priority Account | conf=0.980 | Mapped 'Priority Account from list' to variable 'qLIST_PRIORITY_ACCOUNT' (LIST PRIORITY ACCOUNT) with value 1=PRIORITY. Direct match on data map answer options yields clear mapping, high confidence.
qLIST_PRIORITY_ACCOUNT == 1
# Non-Priority Account | conf=0.980 | Mapped 'Non-Priority Account from list' to variable 'qLIST_PRIORITY_ACCOUNT' (LIST PRIORITY ACCOUNT) with value 2=NOT PRIORITY. Direct match on data map answer options yields clear mapping, high confidence.
qLIST_PRIORITY_ACCOUNT == 2