# HawkTab AI — Generated R Script
# Session: output-2025-08-08T19-23-57-624Z
# Generated: 2025-08-08T19:31:24.409Z

library(haven)
data <- read_sav('temp-outputs/output-2025-08-08T19-23-57-624Z/dataFile.sav')


# ===== Group: Specialty =====
# Total | conf=0.970 | Mapped to status variable; value 3 corresponds to Qualified respondents per data map. Direct, unambiguous mapping.
status == 3
# Cards | conf=0.900 | Mapped S2 and S2a directly; S2=1 (Cardiologist) and S2a=1 (works in cardiologist office). Combined with & per R syntax. Precise but multi-variable, hence moderate-high confidence.
(S2 == 1 & S2a == 1)
# PCPs | conf=0.980 | Mapped to S2 variable; value 2 corresponds to Internal Medicine / General Practitioner / Primary Care / Family Practice (PCP). Direct mapping.
S2 == 2
# Nephs | conf=0.980 | Mapped to S2 variable; value 3 corresponds to Nephrologist. Direct mapping.
S2 == 3
# Endos | conf=0.980 | Mapped to S2 variable; value 4 corresponds to Endocrinologist. Direct mapping.
S2 == 4
# Lipids | conf=0.980 | Mapped to S2 variable; value 5 corresponds to Lipidologist. Direct mapping.
S2 == 5

# ===== Group: Role =====
# Total | conf=0.950 | The data map variable 'status' codes 3 as 'Qualified'; mapping 'qualified respondents' to status == 3 is a direct, unambiguous match.
status == 3
# HCP | conf=0.900 | Interpreted 'HCP' (healthcare professional) as physicians per the 'primary role' variable S2b (1=Physician). Considered using qSPECIALTY %in% c(1,2) but chose S2b for direct role mapping; confidence reduced slightly for conceptual interpretation.
S2b == 1
# NP/PA | conf=0.950 | 'NP/PA' directly corresponds to S2b codes 2 (Nurse Practitioner) and 3 (Physician’s Assistant); this is a precise, direct mapping.
S2b %in% c(2, 3)

# ===== Group: Volume of Adult ASCVD Patients =====
# Total | conf=0.840 | Mapped “qualified respondents” to respondents with non-missing S11, since S11 records the count of adult patients with ASCVD. No dedicated qualifier variable exists, so non-missing S11 indicates qualification.
!is.na(S11)
# Higher | conf=0.400 | Original text is a placeholder. Assumed a median split on S11 to define “Higher” volume. Alternative cutoffs could be used; this is a provisional mapping pending specified threshold.
S11 > median(S11, na.rm = TRUE)
# Lower | conf=0.400 | Original text is a placeholder. Assumed a median split on S11 to define “Lower” volume. Alternative cutoffs could be used; this is a provisional mapping pending specified threshold.
S11 <= median(S11, na.rm = TRUE)

# ===== Group: Tiers =====
# Total | conf=0.800 | Mapped “qualified respondents” to the data map variable status, where 3 = Qualified respondents. Only one plausible match found, hence conceptual inference with high confidence.
status == 3
# Tier 1 | conf=0.950 | Direct mapping to qLIST_TIER which has value 1 = TIER 1 in the data map. Unambiguous match.
qLIST_TIER == 1
# Tier 2 | conf=0.950 | Direct mapping to qLIST_TIER which has value 2 = TIER 2 in the data map. Unambiguous match.
qLIST_TIER == 2
# Tier 3 | conf=0.950 | Direct mapping to qLIST_TIER which has value 3 = TIER 3 in the data map. Unambiguous match.
qLIST_TIER == 3
# Tier 4 | conf=0.950 | Direct mapping to qLIST_TIER which has value 4 = TIER 4 in the data map. Unambiguous match.
qLIST_TIER == 4

# ===== Group: Segments =====
# Total | conf=0.950 | Mapped "qualified respondents" to status == 3 based on data map variable 'status' where 3 = Qualified. Direct match with clear value label.
status == 3
# Segment A | conf=0.600 | Data map contains variable 'Segment' (captured variable) but no answer options defined. Assuming value label exactly matches "Segment A" from the original. Code values not provided; manual verification of actual coding recommended.
Segment == "Segment A"
# Segment B | conf=0.600 | Using the captured variable 'Segment' (no defined codes), assumed label "Segment B" aligns with original. Actual coding format (e.g., numeric vs string) unknown; please confirm.
Segment == "Segment B"
# Segment C | conf=0.600 | Assumed 'Segment' variable holds a label "Segment C" matching the original. No answer options in data map; manual code check needed.
Segment == "Segment C"
# Segment D | conf=0.600 | Mapped to 'Segment' == "Segment D" by assumption of label matching. Data map lacks value definitions; confirm actual coding.
Segment == "Segment D"

# ===== Group: Priority Accounts =====
# Total | conf=0.950 | Mapped "qualified respondents" to the status variable, where status == 3 corresponds to “Qualified” per the data map (Answer_Options: 3=Qualified). Direct variable and value match yields high confidence.
status == 3
# Priority Account | conf=0.950 | Mapped "Priority Account from list" to the qLIST_PRIORITY_ACCOUNT variable (“LIST PRIORITY ACCOUNT”), where 1=PRIORITY. Direct label match with clear mapping.
qLIST_PRIORITY_ACCOUNT == 1
# Non-Priority Account | conf=0.950 | Mapped "Non-Priority Account from list" to the qLIST_PRIORITY_ACCOUNT variable (“LIST PRIORITY ACCOUNT”), where 2=NOT PRIORITY. Direct label match with clear mapping.
qLIST_PRIORITY_ACCOUNT == 2