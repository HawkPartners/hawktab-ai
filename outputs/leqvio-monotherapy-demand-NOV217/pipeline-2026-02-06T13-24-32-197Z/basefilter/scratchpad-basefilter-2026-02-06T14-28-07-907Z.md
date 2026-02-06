# BaseFilterAgent Scratchpad Trace

Generated: 2026-02-06T14:28:07.916Z
Total entries: 91

---
## Entry 1 - 07:58:08.841

**Action**: `add`

[s1] s1:
  Survey: Found '[ASK ALL]' before question S1 in the survey document.
  Logic: Question is asked to all respondents. Response option 3 ('I don’t want to proceed') terminates the survey for that respondent, but it is a valid response, not a show/skip condition for others.
  Intent: Ask to all respondents; no skip/show logic restricts who is asked S1.
  Variables: S1 exists in datamap (categorical_select, values 1-3).
  Action: pass - default base (banner cut + non-NA) is sufficient; no additionalFilter needed.
  Confidence: 1.0 - explicit '[ASK ALL]' instruction.
  Note: baseText left empty to indicate 'All respondents.'

---

## Entry 2 - 07:58:16.068

**Action**: `add`

[s2a] s2a:
  Survey: Found '[ASK IF S2=6 OR 7]' controlling S2a in the screener section.
  Logic: S2a is only displayed when S2 equals 6 (Nurse Practitioner) OR 7 (Physician's Assistant).
  Intent: Ask only respondents whose primary specialty/role is NP or PA.
  Variables: S2 exists in datamap with values 6 = Nurse Practitioner, 7 = Physician's Assistant.
  Action: filter - table-level condition applies to entire question S2a.
  AdditionalFilter: S2 %in% c(6, 7)
  BaseText: 'Asked of respondents who indicated their primary role was Nurse Practitioner or Physician’s Assistant'
  Confidence: 0.95 - explicit '[ASK IF]' present and variables verified in datamap.


---

## Entry 3 - 07:58:25.162

**Action**: `add`

[s2] s2:
  Survey: S2 appears in the Screener and is explicitly marked [ASK ALL]. I reviewed the S2 block: options include routing (e.g., S3a asked if S2=1; S2a asked if S2=6 or 7; option 99=Other triggers TERMINATE). Those routings affect subsequent questions but do not mean S2 was only shown to a subset. 
  Logic: S2 was asked to all respondents. No [ASK IF] or [SHOW IF] limits who is asked S2 itself. Therefore the default base (banner cut + non-NA S2) is correct.
  Variables: S2 exists in the datamap (categorical 1-99).
  Action: pass - no additionalFilter needed.
  Confidence: 1.0 - explicit [ASK ALL] and datamap variable present.
  Note: The userNote correctly documents that certain responses trigger routing/termination; that is relevant for downstream tables but does not change S2's base.

---

## Entry 4 - 07:58:38.206

**Action**: `add`

[s2b] [s2b]:
  Survey: S2 is asked to all respondents (the Screener shows '[ASK ALL]' around S2). S2 lists multiple specialty/role options; follow-ups (S2a, S3a) are conditional on particular S2 answers but S2 itself has no [ASK IF] or [SHOW IF].
  Logic: No explicit skip/show logic affecting who sees S2b. The datamap contains S2b (values 1,2,3,99). Selecting certain S2 options triggers follow-ups or termination but does not change who was asked S2.
  Intent: Ask everyone 'What is your primary role?'.
  Variables: S2b exists in the datamap with allowed values (1,2,3,99).
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.00 - explicit question asked to all, no conditional show/ask around S2b.

---

## Entry 5 - 07:59:05.836

**Action**: `add`

[s3a] s3a:
  Survey: Found '[ASK IF S2=1]' before S3a in the screener section.
  Logic: S3a is only shown to respondents who selected 'Cardiologist' at S2 (S2 == 1).
  Intent: Ask only those who are Cardiologists about their cardiology sub-type.
  Variables: S2 exists in datamap (categorical_select values 1-99). S3a exists (categorical_select values 1-3).
  Action: filter - table-level show logic applies to whole question; add additionalFilter 'S2 == 1'.
  BaseText: 'Those who indicated their primary specialty is Cardiologist.'
  Confidence: 0.95 - explicit '[ASK IF S2=1]' and variables exist in datamap.

---

## Entry 6 - 07:59:24.676

**Action**: `add`

[s4] s4:
  Survey: Found explicit instruction '[ASK IF S2=1-5]' in the survey before S4.
  Logic: S4 is only asked to respondents whose primary specialty (S2) equals 1-5 (Cardiologist, Internal Medicine/GP/Primary Care/Family Practice, Nephrologist, Endocrinologist, Lipidologist).
  Intent: Ask only those whose primary specialty is one of the listed specialties.
  Variables: S2 exists in the datamap with values 1-99; values 1-5 correspond to the specialties above.
  Action: filter - add additionalFilter 'S2 %in% c(1,2,3,4,5)'.
  Confidence: 0.95 - explicit [ASK IF] instruction and variables exist in datamap.
  Notes: The table's userNote correctly states that selecting 'Board Eligible' or 'Neither' triggered termination for the respondent, but that affects downstream routing, not the base of S4 itself. The NET row is valid because component rows share the same base.

---

## Entry 7 - 07:59:42.428

**Action**: `add`

[s5] s5:
  Survey: S5 is marked with [ASK ALL] in the survey screener. The response options 1-6 are marked 'TERMINATE' in the survey text; selecting any of those would terminate the respondent during screening.
  Logic: This is a screener asked to all respondents. There is no [ASK IF] or [SHOW IF] gating who is asked S5. The termination labels affect subsequent participation, not who is asked this question.
  Intent: Ask to all respondents to identify disqualifying affiliations. The question flags termination but does not restrict the question to a subset.
  Variables: S5r1..S5r7 exist in the datamap as binary_flag variables (0/1). Verified.
  Action: pass - banner cut + non-NA is sufficient. No additional filter needed.
  Confidence: 1.0 - explicit [ASK ALL] and variables exist in datamap.
  Note: The table is already marked exclude: true with reason 'Screener question' — leave that as-is.

---

## Entry 8 - 07:59:42.517

**Action**: `add`

[s6] s6:
  Survey: S6 is labeled [ASK ALL] in the screener. The survey includes a termination rule ('TERMINATE IF < 3 OR > 35 YEARS') but there is no '[ASK IF]' or '[SHOW IF]'.
  Logic: Question is asked to all respondents; termination applies after answering (eligibility), not a show/skip condition that would require filtering the analysis base.
  Intent: Ask everyone their years in practice; then remove ineligible respondents from the survey flow.
  Variables: S6 exists in the datamap with allowed values 3-35.
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 - explicit [ASK ALL], variable present, unambiguous.

---

## Entry 9 - 08:00:20.898

**Action**: `add`

[s6_binned] s6_binned:
  Survey: No explicit skip/show logic found for S6. S6 is an early screener question asked to all respondents. Survey includes text: 'TERMINATE IF < 3 OR > 35 YEARS'.
  Logic: The only constraint is a termination rule applied during screening; S6 itself has no [ASK IF] or [SHOW IF]. The termination means the dataset contains only respondents with S6 in 3-35.
  Intent: Ask all eligible respondents for years in practice; respondents outside 3-35 were screened out and do not appear in data.
  Variables: S6 exists in datamap with allowed values 3-35.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter needed.
  Confidence: 1.00 - explicit survey termination rule and matching datamap values confirm this decision.

---

## Entry 10 - 08:00:32.043

**Action**: `add`

[s8] s8:
  Survey: S8 is marked [ASK ALL] in the screener section.
  Logic: There's a sampling termination rule: "MUST SPEND AT LEAST 70% OF TIME ON S8A-TREATING/MANAGING PATIENTS, ELSE TERMINATE". This is enforced during screening (respondents with S8r1 < 70 are terminated and not in final sample).
  Intent: Question was asked to all eligible respondents (no conditional show/ask logic to restrict who sees S8 beyond study qualification). The 70% rule is a pre-qualification (screen-out) rather than a per-row show condition.
  Variables: S8r1, S8r2, S8r3, S8r4 exist in datamap. S8r1's allowed values are 70-100, reflecting the screening requirement.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required.
  Confidence: 1.0 - explicit [ASK ALL] and datamap enforces screening; unambiguous.

---

## Entry 11 - 08:00:38.846

**Action**: `add`

[s7] s7:
  Survey: Found S7 in SCREENER. The question header is marked [ASK ALL]. The response option 'Part-Time' is annotated with 'TERMINATE'.
  Logic: S7 was asked to all respondents; selecting Part-Time triggers termination AFTER answering S7. There is no [ASK IF] or [SHOW IF] that would limit who saw S7.
  Intent: Ask only to all respondents (screener). Termination simply removes Part-Time respondents from further survey paths, it does not restrict the base for S7 itself.
  Variables: S7 exists in the datamap (categorical_select; values 1=Full-Time, 2=Part-Time).
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required.
  Confidence: 1.00 - explicit [ASK ALL], variable present, unambiguous. Note: The table is already excluded as a screener variable per VerificationAgent; we leave that unchanged.

---

## Entry 12 - 08:01:25.180

**Action**: `add`

[s8_S8r1_distribution] s8_S8r1_distribution:
  Survey: S8 appears under SCREENER and is marked [ASK ALL]. The instructions include a hard screener: "MUST SPEND AT LEAST 70% OF TIME ON S8A-TREATING/MANAGING PATIENTS, ELSE TERMINATE". 
  Logic: Only respondents who spend >=70% on S8r1 remain in the survey (others terminated). This is explicit screening applied at data collection.
  Intent: Ask S8 to all qualifying respondents; screen out those with <70% time on treating/managing patients.
  Variables: S8r1 exists in the datamap and its allowed values are 70-100, confirming only >=70 were captured.
  Action: pass - banner cut + non-NA is sufficient. No per-row show logic; screen enforced in collection and datamap domain.
  Confidence: 0.95 - explicit screener and datamap confirm.


---

## Entry 13 - 08:01:26.245

**Action**: `add`

[s10] s10:
  Survey: S10 is labeled [ASK ALL] in the survey screener. It asks: "Using your best estimate, how many adult patients... per month?"
  Logic: There is a screening rule on S10: "TERMINATE IF <50". This is a termination/screener rule, not a show/ask-if condition that restricts who sees a later question. S10 itself is asked to all respondents reaching that step.
  Datamap check: Variable S10 exists in the datamap with allowed Values: 56-999 (consistent with the screener enforced). No separate condition variables referenced.
  Intent: The question was asked to all eligible respondents; the <50 rule is a screening termination (removes respondents who don't meet quota) rather than conditional show logic that would require an additionalFilter for S10's base.
  Action: pass - default base (banner cut + non-NA S10) is sufficient.
  Confidence: 1.0 - explicit [ASK ALL] and clear screener rule; variable exists in datamap.
  Note: userNote correctly documents the screening criterion; no additionalFilter needed.

---

## Entry 14 - 08:01:33.908

**Action**: `add`

[s9] s9:
  Survey: Found S9 in SECTION S: SCREENER and marked with [ASK ALL].
  Logic: No [ASK IF] or [SHOW IF] applying to S9 was found. (Answer option 7 shows 'TERMINATE' in the survey text, which is an exit after answering, not a pre-filter.)
  Intent: Ask this question of all respondents (screener asked to all).
  Variables: S9 exists in the datamap (categorical_select, values 1-8).
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 - explicit [ASK ALL], variable present, no ambiguity.
  Note: Though selecting VA Hospital (7) may terminate the respondent after answering, it does not change who was asked S9; therefore no additional filter is required.

---

## Entry 15 - 08:02:08.342

**Action**: `add`

[s10_binned] s10_binned:
  Survey: S10 is asked to all respondents (in SCREENER). Survey text includes "TERMINATE IF <50" after S10.
  Logic: This is a hard screener termination — respondents managing fewer than 50 adult patients/month are removed from the survey. That means the remaining sample all have S10 >= 50.
  Intent: S10 is asked to everyone in the qualifying sample (no SHOW/ASK IF that would limit the question to a subgroup). The termination is not a per-row show logic; it's a precondition that was applied before completing the survey.
  Variables: S10 exists in the datamap; allowed values in datamap start at 56 and go to 999 (i.e., no values <50 present). Variable name verified: S10.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required.
  Confidence: 1.0 - explicit screener and datamap confirm the domain; no ambiguity.

---

## Entry 16 - 08:02:27.673

**Action**: `add`

[s11_binned] s11_binned:
  Survey: S11 appears under the SCREENER section with an explicit '[ASK ALL]' heading. No '[ASK IF]' or '[SHOW IF]' is present for S11.
  Logic: No question-level skip/show logic; there are general screener termination rules elsewhere (e.g., terminate if S10 <50, S11 <10), but these are qualification checks, not per-question show logic.
  Intent: Ask all (qualified) respondents to report the number of patients with hypercholesterolemia and CVD. There is no per-row or piped/looped logic.
  Variables: S11 exists in the datamap as numeric_range (values 20-900). Verified variable present.
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter needed.
  Confidence: 1.0 - explicit '[ASK ALL]' and variable exists in datamap.

---

## Entry 17 - 08:02:48.417

**Action**: `add`

[s11] s11:
  Survey: S11 appears in the SCREENER section. The survey shows S10 (number of adult patients managed per month) with 'TERMINATE IF <50'. S11 follows: 'Of those [S10] adult patients ... how many have confirmed hypercholesterolemia with established CVD? ALLOW 0-S10. TERMINATE IF <10'.
  Logic: S11 is asked to respondents who passed earlier screener checks (i.e., those who reached this point). Respondents terminated earlier would not be asked S11 and should have NA for S11.
  Intent: Table-level - ask all qualified respondents for a numeric count. Not a per-row follow-up or piped loop.
  Variables: S11 exists in the datamap as numeric_range (Values: 20-900). Therefore variable exists and has valid numeric values.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required because non-asked respondents will be NA; the question is not a row-level follow-up requiring splitting.
  Confidence: 0.95 - explicit screener instructions and S11 variable present in datamap. No ambiguous show/ask logic that would require a refinement.

---

## Entry 18 - 08:02:55.111

**Action**: `review`

[s11] Check S11 datamap: S11 Type numeric_range Values 20-900. Survey text: S11 allows 0-S10. But datamap's Values 20-900 indicates during fielding only values >=20? Wait datamap shows S11: Values: 20-900, but in survey S11 allowed 0-S10 and terminate if <10. There is potential mismatch: however datamap has S11 variable and values show range that may reflect survey's quota or real responses. But key: S11 exists and respondents who didn't qualify were terminated earlier, so their S11 is NA.
Therefore action pass remains valid.

---

## Entry 19 - 08:03:08.213

**Action**: `add`

[s12] s12:
  Survey: Found S12 immediately follows S11 with instruction '[ASK ALL – POP UP ON SAME SCREEN AFTER S11 IS ANSWERED]' and S11 has 'TERMINATE IF <10'. S12 lines include: 'SUM MUST BE < OR = S11' and 'TERMINATE IF D = 0' (termination if sum=0). 
  Logic: S12 is a follow-up asking respondents to break down the S11 count by time-since-event. It is only asked to respondents who passed the S11 screener (manage ≥10 relevant patients). 
  Intent: Ask only those who manage ≥10 adult patients with hypercholesterolemia & established CVD (i.e., S11 >= 10). This is table-level show logic (the whole question is conditioned on S11).
  Variables: S11 exists in datamap (numeric_range). S12r1-S12r4 exist. 
  Action: filter - add additionalFilter 'S11 >= 10' to ensure base matches who were asked S12.
  Confidence: 0.95 - explicit screening logic present, variable exists in datamap.
  Note: No row-level split needed; NETs not present. 'TERMINATE IF D = 0' refers to sum validation but doesn't change the base filtering requirement.

---

## Entry 20 - 08:03:31.360

**Action**: `add`

[s12_total] [s12_total]:
  Survey: Found 'POP UP ON SAME SCREEN AFTER S11 IS ANSWERED' and 'TERMINATE IF D = 0' and 'AUTO-SUM. SUM MUST BE <= S11'. S11 contains explicit qualification logic: 'TERMINATE IF <10'.
  Logic: S12 is presented immediately after S11 to respondents who passed S11 (i.e., qualified respondents managing >=10 adult patients with hypercholesterolemia and established CVD). There is no separate [ASK IF] or per-row show logic indicating that any of the four S12 rows are shown to only a subset of those respondents.
  Intent: Ask all qualified respondents the four S12 time-window counts; the table is a derived sum of those four counts.
  Variables: S12r1, S12r2, S12r3, S12r4 exist in the datamap (numeric ranges). No separate condition variables (e.g., S11rX flags) were found for row-level filtering.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required.
  Confidence: 0.95 - explicit qualification via S11; variables present and no row-level show logic found.
  Note: The instruction 'TERMINATE IF D = 0' in the survey text is ambiguous in isolation but appears to control termination based on a particular response rather than indicating a row-level show condition. It does not change the base for S12 (respondents must have qualified via S11).

---

## Entry 21 - 08:03:53.386

**Action**: `add`

[s12_total_binned] s12_total_binned:
  Survey: Located S12 in SCREENER section (immediately after S11). S12 is shown after S11 and inside the "IF QUALIFIED" block.
  Logic found: S11 has screening logic (TERMINATE IF <10). S12 is asked to those who qualify (i.e., passed S11). S12 also contains a line "TERMINATE IF D = 0 AUTO-SUM. SUM MUST BE < OR = S11" — this is an internal validation/termination rule but not a per-row show/skip that restricts S12 to a subgroup beyond the qualifier.
  Intent: Ask S12 to all qualified respondents (those who passed S11). No per-row show logic (each S12r1-S12r4 is a time-slice of the same question).
  Variables: S12r1, S12r2, S12r3, S12r4 exist in the datamap. _NET_S12_TOTAL is a derived aggregation used for binning; netComponents reference the four S12 rows.
  Action: pass - banner cut to qualified respondents (already captured in baseText) + non-NA responses is sufficient. No additionalFilter required.
  Confidence: 0.95 - explicit screener gating and direct question placement; the ambiguous "D = 0" termination does not change who is asked the question.

---

## Entry 22 - 08:03:58.191

**Action**: `add`

[a1] a1:
  Survey: No '[ASK IF]' or '[SHOW IF]' or 'Base:' instruction found for A1 in the survey text. A1 appears under Section A with an introductory instruction to focus on uncon trolled LDL-C patients, but that is a general prompt, not skip/show logic.
  Logic: None explicit for A1. No per-row show logic (e.g., "ONLY SHOW THERAPY WHERE A3>0") is present for A1. Later questions (A3, A3a, A3b) do have row-level show logic, but that pattern does not apply here.
  Intent: Ask A1 to all qualified respondents who progressed past the screener. No additional constraints beyond the normal banner cut/non-NA are required.
  Variables: A1r1, A1r2, A1r3, A1r4 exist in the datamap and match the table rows.
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 - clear absence of any skip/show instruction and variables verified in datamap.

---

## Entry 23 - 08:04:20.591

**Action**: `add`

[a2a] a2a:
  Survey: No '[ASK IF]' or '[SHOW IF]' found for A2a in survey document. A2a appears after A1 and before A2b and is not conditional.
  Logic: No skip/show logic. Question is presented to all qualified respondents who progressed to Section A.
  Intent: Ask everyone in the main sample (post-screener qualification) — no extra filter required.
  Variables: A2a exists in datamap (categorical_select, values 1-3).
  Action: pass - default base (banner cut + non-NA for A2a) is sufficient.
  Confidence: 0.95 - explicit absence of skip/show logic and variable verified in datamap.

---

## Entry 24 - 08:04:28.540

**Action**: `add`

[a2b] [a2b]:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A2b in the questionnaire. A2a and A2b appear as general knowledge questions after A1.
  Logic: No skip/show logic detected; A2b is presented to all respondents who qualify for the main survey (i.e., past screening). Qualification is handled by banner cut.
  Intent: Ask to all qualified respondents (no per-row/show logic).
  Variables: A2b exists in datamap (categorical_select values 1-3).
  Action: pass - banner cut + non-NA is sufficient.
  Confidence: 1.0 - clear absence of show/skip logic; variable confirmed in datamap.


---

## Entry 25 - 08:04:41.055

**Action**: `add`

[a3] a3:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A3 itself. A3 appears after screener and is shown to "IF QUALIFIED" respondents (standard banner cut).
  Logic: A3 asks respondents to indicate counts (out of their last 100 patients) for each therapy. There is no per-row show/skip instruction for A3. Follow-ups (A3a, A3b) DO have show logic: "ONLY SHOW THERAPY WHERE A3>0", but that applies to A3a/A3b only.
  Intent: Ask all qualified respondents about how many of their last 100 uncontrolled LDL-C patients received each therapy; responses of 0 are valid and should be included.
  Variables: A3r1..A3r7 exist in datamap and are numeric_range/categorical_select as expected.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required.
  Confidence: 0.95 - explicit absence of skip/show logic for A3; follow-up show logic does not change A3 base.

---

## Entry 26 - 08:05:11.127

**Action**: `add`

[a3_A3r2_bins] a3_A3r2_bins:
  Survey: Located question A3 in Section A. No explicit [ASK IF] or [SHOW IF] for A3 itself beyond the earlier qualification step ("IF QUALIFIED: ...").
  Logic: A3 is asked to qualified respondents to report counts (0-100) for each therapy row. The follow-up A3a/A3b contain explicit conditional logic ("ONLY SHOW THERAPY WHERE A3>0"), but that applies to A3a/A3b, not to A3r2 itself. A3r2 allows 0 as a valid response (datamap shows allowed values including 0).
  Intent: Ask all qualified respondents for counts of patients prescribed Leqvio among their last 100 patients; 0 is a valid answer meaning none.
  Variables: A3r2 exists in datamap (categorical_select or numeric range as documented). No separate 'owns' or usage variable exists for Leqvio that would indicate row-level show logic for A3.
  Action: pass - No additionalFilter needed. Banner cut + non-NA is sufficient. The pipeline's banner already handles qualification; A3 has no per-row show logic.
  Confidence: 0.95 - explicit absence of skip/show for A3; follow-ups are conditional but do not affect this table.


---

## Entry 27 - 08:05:21.676

**Action**: `add`

[a3_A3r1_bins] [a3_A3r1_bins]:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A3 in the questionnaire. A3 is in Section A and is asked to qualified respondents after screener.
  Logic: A3 asks "For your LAST 100 patients... indicate for how many you prescribed each..." — this is asked to all respondents who passed screening. There is a downstream instruction for A3a: "ONLY SHOW THERAPY WHERE A3>0", but that applies to A3a (follow-up) and is row-level for A3a, not a filter on A3 itself.
  Intent: A3 (and A3r1) should be asked to all qualified respondents. No additional constraint is required beyond banner cut + non-NA.
  Variables: A3r1 exists in the datamap (numeric_range 0-100).
  Action: pass - default base is sufficient.
  Confidence: 1.0 - explicit absence of skip/show logic and variable present.

---

## Entry 28 - 08:05:45.905

**Action**: `add`

[a3_A3r3_bins] a3_A3r3_bins:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A3 in survey document. A3 is presented to "remaining respondents" after qualification; there is no per-therapy gating for A3 itself.
  Logic: A3a/A3b include instructions "ONLY SHOW THERAPY WHERE A3>0" which apply to follow-up questions (A3a/A3b), not to the parent A3 question. Therefore A3 (and A3r3) was asked to all qualified respondents and can legitimately be 0.
  Intent: Ask all qualified respondents to report counts (0-100) for each therapy in their last 100 patients.
  Variables: A3r3 exists in datamap as numeric_range 0-100 (Praluent counts). Verified variable name: A3r3.
  Action: pass - default base (banner cut + non-NA for A3r3) is sufficient; no additionalFilter needed.
  Confidence: 1.0 - explicit absence of show logic for A3, variable present, value 0 is meaningful.

---

## Entry 29 - 08:06:01.729

**Action**: `add`

[a3_A3r4_bins] a3_A3r4_bins:
  Survey: Located A3 in Section A. No explicit '[ASK IF]' or '[SHOW IF]' appears before A3. The question text asks about the respondent's LAST 100 patients and is presented to qualified respondents. Follow-up questions (A3a, A3b) contain show logic like 'ONLY SHOW THERAPY WHERE A3>0' but that applies to those follow-ups, not to A3 itself.
  Logic: No skip/show logic applies to A3 rows. A3 is asked to all qualifying respondents; the instruction to 'focus on patients with uncontrolled LDL-C' is a framing instruction, not a conditional branch.
  Intent: Ask A3 to all qualified respondents (no per-row or table-level show logic found).
  Variables: A3r4 exists in datamap (A3r4: Repatha - numeric range 0-60). 0 is a valid coded response (none), not NA.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required.
  Confidence: 0.95 - explicit absence of show logic; follow-ups are conditional but do not change the base for A3.


---

## Entry 30 - 08:06:27.490

**Action**: `add`

[a3_A3r5_bins] a3_A3r5_bins:
  Survey: Located A3 in survey. No explicit [ASK IF] or [SHOW IF] around A3 itself. A3 is introduced under "IF QUALIFIED" (survey gating), but that is upstream and handled by the banner cut.
  Logic: A3 asks respondents to indicate counts (0-100) for each therapy for their LAST 100 patients. The A3r5 item (Zetia/ezetimibe) is a direct row in A3 with allowed values 0-95. There is no per-row SHOW/ASK condition for A3r5 in the survey text. Follow-up A3a/A3b include "ONLY SHOW THERAPY WHERE A3>0", but that applies to A3a/A3b, not A3 itself.
  Intent: Ask A3 (including A3r5) to all respondents who qualified for the survey. No additional table-level or row-level filter beyond the standard banner cut + non-NA is required.
  Variables: A3r5 exists in the datamap (numeric_range 0-95). No condition variables referenced for A3 rows.
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 - explicit absence of skip/show logic for A3; datamap confirms variable existence and coding.

---

## Entry 31 - 08:06:29.110

**Action**: `add`

[a3_A3r6_bins] a3_A3r6_bins:
  Survey: Located question A3 'For your LAST 100 patients...' in the survey instrument. No explicit [ASK IF] or [SHOW IF] appears for A3. The only conditional language references A3a/A4a ("ONLY SHOW THERAPY WHERE A3>0"), which applies to the follow-up percent-of treatment questions, not to A3 itself.
  Logic: There is no skip/show logic that restricts who is asked A3 or the Nexletol row (A3r6). A3 is a core allocation question asked to all qualified respondents. 
  Intent: Ask everyone (who qualified) to report counts across all therapies for their last 100 patients. Follow-up questions (A3a/A3b) are conditioned on A3>0, but that does not change the base for A3.
  Variables: A3r6 exists in the datamap (allowed values 0-50) — verified.
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter needed.
  Confidence: 1.0 - explicit absence of skip/show logic and variable verification.


---

## Entry 32 - 08:06:53.917

**Action**: `add`

[a3_A3r7_bins] a3_A3r7_bins:
  Survey: Located A3 in survey. A3 (LAST 100 patients per therapy) is asked to qualified respondents (IF QUALIFIED) but has no [ASK IF] or [SHOW IF] controlling individual rows. A3a and other follow-ups contain 'ONLY SHOW THERAPY WHERE A3>0' logic, but that applies to follow-up questions, not A3 itself.
  Logic: A3 is asked to all qualified respondents; A3r7 (Other) is a direct response variable with allowed values 0-20 in datamap.
  Intent: Ask all qualified respondents to indicate counts for each therapy in their last 100 patients.
  Variables: A3r7 exists in datamap (A3r7: Other, values 0-20).
  Action: pass - no additional filter required beyond the banner cut + non-NA.
  Confidence: 0.95 - explicit in survey: A3 is an early question asked to all qualified participants; the per-row show logic appears only in follow-ups (A3a/A3b) which is not this table.


---

## Entry 33 - 08:07:35.399

**Action**: `add`

[a3b] a3b (overall):
  Survey: Found explicit show logic in A3b prompt: "ONLY SHOW ROWS FOR WHICH A3a COL B > 0" (and A3a itself is shown only where A3>0). A3a variables for "Without a statin" are A3ar1c2..A3ar5c2 in datamap. A3b rows are A3br1c1/A3br1c2..A3br5c1/A3br5c2. 
  Logic: Each therapy's A3b rows are only asked if respondent reported prescribing that therapy without a statin in A3a (i.e., A3arXc2 > 0).
  Intent: Row-level show logic — the condition applies per therapy row, not to the entire question.
  Variables: A3ar1c2, A3ar2c2, A3ar3c2, A3ar4c2, A3ar5c2 exist in datamap (numeric 0-100). 
  Action: split - create one table per therapy with an additionalFilter limiting the base to respondents with A3arXc2 > 0.
  Confidence: 0.95 - explicit instruction in survey and variables exist in datamap.

Per-split details:
  Leqvio: filter A3ar1c2 > 0 -> rows A3br1c1/A3br1c2
  Praluent: filter A3ar2c2 > 0 -> rows A3br2c1/A3br2c2
  Repatha: filter A3ar3c2 > 0 -> rows A3br3c1/A3br3c2
  Zetia: filter A3ar4c2 > 0 -> rows A3br4c1/A3br4c2
  Nexletol/Nexlizet: filter A3ar5c2 > 0 -> rows A3br5c1/A3br5c2

NETs: none present. No removal required.

Recommendation: Split into 5 tables, each with additionalFilter as above, baseText describing respondents who reported prescribing that therapy without a statin. filterReviewRequired: false; humanReviewRequired: false.

---

## Entry 34 - 08:07:55.864

**Action**: `add`

[a3a] [a3a]:
  Survey: Found explicit instruction before A3a: "ONLY SHOW THERAPY WHERE A3>0" (per-therapy show logic).
  Logic: A3a rows are shown only for therapies the respondent reported >0 in A3 (their LAST 100 patients). This is row-level show logic (per therapy).
  Intent: Ask respondents about In addition to statin / Without a statin only for therapies they actually reported prescribing to at least one of their last 100 patients.
  Variables: Datamap has A3r2 (Leqvio), A3r3 (Praluent), A3r4 (Repatha), A3r5 (Zetia), A3r6 (Nexletol). These map to the therapies in A3 and exist.
  Action: split - create one table per therapy (each table contains the two A3a rows for that therapy) and add per-therapy filter (A3rX > 0).
  Base text examples: "Respondents who reported prescribing Leqvio to at least one of their last 100 patients." etc.
  Confidence: 0.95 - explicit show logic and variables exist.
  Notes: No NET rows present. Aggregating across therapies without applying per-row filters would mix different respondent pools and produce invalid percentages.

---

## Entry 35 - 08:08:04.667

**Action**: `add`

[a3b_leqvio_dist] a3b_leqvio_dist:
  Survey: Found explicit show logic 'ONLY SHOW ROWS FOR WHICH A3a COL B > 0' for A3b in the survey document.
  Logic: A3b rows (distribution of % 'before'/'after') are only shown for treatments where the A3a column B ('Without a statin') > 0.
  Intent: Ask only respondents who reported prescribing that therapy without a statin to answer this distribution question about those patients.
  Variables: A3ar1c2 is the datamap variable for Leqvio's A3a 'Without a statin' percentage (exists in datamap). A3br1c1/A3br1c2 are the A3b distribution variables used in the table rows (exist in datamap).
  Action: filter - apply table-level additionalFilter "A3ar1c2 > 0" so the base includes only respondents who reported >0% prescribing Leqvio without a statin.
  Rationale: Show logic is explicit and applies at the question (treatment) level; both 'Before' and 'After' rows share that same condition. Filtering is straightforward and variables exist.
  Confidence: 0.95 - explicit instruction and variables verified.

---

## Entry 36 - 08:09:36.261

**Action**: `add`

[a3b_nexletol_dist] a3b_nexletol_dist:
  Survey: Found explicit show logic for A3b: "IF COL B (WITHOUT A STATIN) IN A3a FOR ANY ROW > 0" and "ONLY SHOW ROWS FOR WHICH A3a COL B > 0". This means A3b rows are shown only for therapies where the respondent reported >0% in A3a (the 'Without a statin' column).
  Logic: For Nexletol, the corresponding A3a 'Without a statin' variable is A3ar5c2 (exists in datamap). Therefore the Nexletol A3b distribution (A3br5c1/A3br5c2) should only include respondents with A3ar5c2 > 0.
  Intent: Ask only respondents who indicated they prescribe Nexletol without a statin.
  Variables: A3ar5c2 exists in datamap; A3br5c1/A3br5c2 are the distribution variables in this table.
  Action: filter - add additionalFilter: "A3ar5c2 > 0" to restrict base to those actually asked the question.
  Confidence: 0.95 - explicit show logic and matching variables present in datamap.
  Note: Non-NA alone is insufficient because a 0 value in A3ar5c2 indicates '0%' (not shown) but the survey's logic shows A3b only when A3ar5c2 > 0; thus we filter on > 0 rather than non-NA.

---

## Entry 37 - 08:09:53.622

**Action**: `add`

[a3b_praluent_dist] a3b_praluent_dist:
  Survey: Found explicit show logic in questionnaire around A3b: "IF COL B (WITHOUT A STATIN) IN A3a FOR ANY ROW > 0. ONLY SHOW ROWS FOR WHICH A3a COL B > 0" (A3b question block).
  Logic: A3b (breakdown of 'before/after' distribution) is only asked for therapies where the respondent indicated they prescribe that therapy without a statin in A3a (i.e., A3a column B > 0).
  Intent: Ask only respondents who reported prescribing the specific therapy without a statin.
  Variables: A3ar2c2 exists in the datamap (numeric_range 0-100) and corresponds to A3a 'Without a statin' for Praluent (alirocumab).
  Action: filter - add additionalFilter "A3ar2c2 > 0" so the base is only respondents who reported >0% Praluent prescriptions without a statin.
  Confidence: 0.95 - explicit SHOW/ONLY SHOW instruction in survey and the condition variable exists in datamap.
  Notes: This is table-level logic (applies to all rows for Praluent). No split required. baseText updated to plain English explaining who was asked.

---

## Entry 38 - 08:09:59.211

**Action**: `add`

[a3b_repatha_dist] a3b_repatha_dist:
  Survey: Found explicit show logic in A3b: "ONLY SHOW ROWS FOR WHICH A3a COL B > 0" (i.e., only show therapies for which respondents indicated >0% prescribe without a statin).
  Logic: For Repatha rows (A3br3c1/A3br3c2), the condition is A3a (Without a statin) for Repatha > 0.
  Intent: Ask only respondents who reported prescribing Repatha without a statin.
  Variables: A3ar3c2 exists in the datamap (numeric_range 0-100) and represents A3a column B (Without a statin) for Repatha. A3br3c1/A3br3c2 are the distribution vars used in this table.
  Action: filter - apply table-level additionalFilter: A3ar3c2 > 0 because the table contains only Repatha rows and the show logic applies to those rows.
  Confidence: 0.95 - explicit show logic and matching datamap variable confirmed.

---

## Entry 39 - 08:10:34.170

**Action**: `add`

[a3b_zetia_dist] a3b_zetia_dist:
  Survey: Found explicit show logic for A3b: 'ONLY SHOW ROWS FOR WHICH A3a COL B > 0' (A3b is only asked for therapies where A3a 'Without a statin' > 0).
  Logic: A3b shown only to respondents who indicated some patients receive that therapy without a statin.
  Intent: Ask only those who prescribe Zetia (ezetimibe) without a statin.
  Variables: A3ar4c2 (A3a, 'Without a statin' for Zetia) exists in datamap. A3br4c1/A3br4c2 (A3b responses) also exist.
  Action: filter - Table-level filter (table covers a single therapy, Zetia). Use additionalFilter 'A3ar4c2 > 0'.
  Confidence: 0.95 - explicit show logic and variables exist in datamap.

---

## Entry 40 - 08:11:04.672

**Action**: `add`

[a4] a4:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found on question A4 itself.
  Logic: A4 is a hypothetical future-state allocation question asked to respondents about their NEXT 100 patients. Follow-up items (A4a/A4b) include row-level show logic such as 'ONLY SHOW THERAPY WHERE A4>0', but that applies to subsequent percent-breakdown questions, not to A4 counts.
  Intent: Ask A4 to all qualified respondents (those who passed screener). There is no table-level show/skip condition that would restrict who sees A4.
  Variables: A4r1c1..A4r7c2 exist in the datamap and are the A4/A3 reference variables.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter required.
  Confidence: 0.95 - explicit absence of skip/show logic for A4; follow-up questions have row-level show logic but do not change A4's base.
  Notes: A4a/A4b and A5 have their own show logic and will need separate review when those tables are processed.

---

## Entry 41 - 08:11:23.429

**Action**: `add`

[a4_next100] [a4_next100]:
  Survey: Located A4 in Section A. A4 text and nearby instructions do not contain any explicit [ASK IF] or [SHOW IF] directives. The screening/qualification steps (S10/S11/S12 and the IF QUALIFIED message) determine who proceeds to Section A, but that is a banner cut applied earlier.
  Logic: No explicit skip/show on A4 itself. Follow-ups (A4a, A4b) include "ONLY SHOW THERAPY WHERE A4>0" which is conditional on values entered in A4, but that is row-level logic for the follow-up items, not show logic that would change A4's base.
  Intent: A4 is intended to be asked to all qualified respondents (those who passed screener). No per-row conditions were found that would require splitting the table rows.
  Variables: Verified variables exist in datamap: A4r1c2, A4r2c2, A4r3c2, A4r4c2, A4r5c2, A4r6c2, A4r7c2.
  Action: pass - default base (banner cut + non-NA) is sufficient; no additionalFilter needed.
  Confidence: 0.95 - clear absence of explicit skip/show logic affecting A4; variables verified.

---

## Entry 42 - 08:11:24.873

**Action**: `add`

[a4_last100] a4_last100:
  Survey: No explicit [ASK IF] or [SHOW IF] found for question A4 in the questionnaire. A4 appears as a follow-on scenario asked to qualified respondents; the question text includes the respondents' A3 answers for reference.
  Logic: The only conditional text referencing A4 is in A5: "ASK IF PRESCRIBING IN A4 is > or < A3 FOR ROWS 2, 3, OR 4", which implies A4 must be available for everyone so the comparison can be evaluated. A4a/A4b include "ONLY SHOW THERAPY WHERE A4>0" but these are subsequent follow-ups (they control which rows are shown in A4a/A4b) and do not change who was asked A4 itself.
  Intent: Ask A4 to all qualified respondents (same sample that saw A3). The A4 "LAST 100" column is provided for reference and replicates A3 responses; no per-row show logic in A4 requires splitting rows or applying additional filters to the A4 last-100 columns.
  Variables: A4r1c1..A4r7c1 exist in the datamap (numeric_range variables). Confirmed variables present.
  Action: pass - default base (banner cut + non-NA on each A4 variable) is sufficient. No additionalFilter needed.
  Confidence: 0.95 - explicit absence of skip/show and presence of conditionals that imply A4 was asked broadly.

---

## Entry 43 - 08:12:26.443

**Action**: `add`

[a5] a5:
  Survey: Found explicit conditional: "ASK IF PRESCRIBING IN A4 is > or < A3 FOR ROWS 2, 3, OR 4 (LEQVIO, REPATHA, OR PRALUENT)" before question A5.
  Logic: Ask A5 only if prescribing in A4 differs from A3 for any of rows 2, 3, or 4 (Leqvio, Praluent, Repatha).
  Intent: Table-level filter — A5 is a single question asked only to respondents who reported a change for any of those three therapies.
  Variables: Compared variables exist in datamap: A3r2 (A3 Leqvio), A4r2c2 (A4 Leqvio NEXT 100), A3r3 (A3 Praluent), A4r3c2 (A4 Praluent NEXT 100), A3r4 (A3 Repatha), A4r4c2 (A4 Repatha NEXT 100).
  Expression: (A4r2c2 != A3r2) | (A4r3c2 != A3r3) | (A4r4c2 != A3r4)
  Action: filter - apply table-level constraint so base matches who were asked A5.
  Confidence: 0.95 - explicit skip/show logic and matching datamap variables.
  Note: NET row is valid because all rows share same question-level base; no split required.


---

## Entry 44 - 08:12:32.140

**Action**: `add`

[a4a] a4a:
  Survey: Found explicit instruction in A4a: "ONLY SHOW THERAPY WHERE A4>0" (A4 = Next 100 counts per therapy).
  Logic: Row-level show logic — each therapy row in A4a is shown only when the corresponding A4 (NEXT 100) count for that therapy is > 0.
  Intent: Ask distribution (in addition/without statin) only for therapies the respondent said they would prescribe for NEXT 100 patients.
  Variables: Mapping verified in datamap:
    - Leqvio A4a rows: A4ar1c1 / A4ar1c2  -> condition variable A4r2c2 (Leqvio NEXT 100) exists
    - Praluent A4a rows: A4ar2c1 / A4ar2c2 -> condition variable A4r3c2 (Praluent NEXT 100) exists
    - Repatha A4a rows: A4ar3c1 / A4ar3c2  -> condition variable A4r4c2 exists
    - Zetia A4a rows: A4ar4c1 / A4ar4c2    -> condition variable A4r5c2 exists
    - Nexletol A4a rows: A4ar5c1 / A4ar5c2 -> condition variable A4r6c2 exists
  Action: SPLIT - produce one table per therapy pair with additionalFilter "<corresponding A4r#c2> > 0".
  Base text: "Those who said they would prescribe [Therapy] to at least one of the NEXT 100 patients."
  filterReviewRequired: false
  Confidence: 0.95 - explicit show logic and condition variables exist in datamap.
  Note: Default banner cut + non-NA is insufficient because rows were not shown to respondents who answered 0 for that therapy in A4; therefore base must be restricted per row.

---

## Entry 45 - 08:12:42.722

**Action**: `add`

[a4b] a4b:
  Survey: Found explicit show logic in survey for A4b: "ONLY SHOW THERAPY WHERE A4>0" and "ONLY SHOW ROWS FOR WHICH A4a COL B > 0" preceding A4b.
  Logic: A4b rows are shown only when respondent indicated a >0% 'Without a statin' value in A4a for that specific therapy.
  Intent: Row-level show logic — each therapy's 'Before'/'After' pair is asked only if respondent indicated they would prescribe that therapy without a statin (>0%) in A4a.
  Variables: Conditional variables exist in datamap: A4ar1c2 (Leqvio), A4ar2c2 (Praluent), A4ar3c2 (Repatha), A4ar4c2 (Zetia), A4ar5c2 (Nexletol). A4br1c1/A4br1c2 etc (A4b rows) exist as table rows.
  Action: split - create one table per therapy (each containing its two rows: Before and After) and apply therapy-specific filter (e.g., A4ar1c2 > 0).
  Confidence: 0.95 - explicit show logic present and corresponding variables exist in datamap.
  Notes: No NETs to remove. filterReviewRequired: false, humanReviewRequired: false.

---

## Entry 46 - 08:13:32.965

**Action**: `add`

[a6] a6:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A6 in the questionnaire. A6 is a ranking question presented after A5; text frames a hypothetical scenario for NEXT 100 patients but does not restrict who is asked. 
  Logic: No skip/show logic in survey text for A6. There is conditional instruction earlier that applies to A5 (ASK IF PRESCRIBING IN A4 is > or < A3 for rows 2,3,4) but that does not reference A6. 
  Intent: Ask all qualifying respondents (banner cut) to rank treatment paths for the hypothetical NEXT 100 patients — not subset filtering. 
  Variables: A6r1..A6r8 exist in datamap as categorical_select with values 1-4. Verified. 
  Action: pass - default base (banner cut + non-NA) is sufficient. 
  Confidence: 0.95 - explicit absence of show logic, variables exist in datamap, straightforward ranking question.

---

## Entry 47 - 08:13:59.906

**Action**: `add`

[a6_detail_A6r1] a6_detail_A6r1:
  Survey: Located A6 in Section A. Question text frames a hypothetical scenario for "NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy" and asks respondents to rank treatment paths. There is NO '[ASK IF]' or '[SHOW IF]' or 'Base:' instruction attached to A6 in the questionnaire. A5 has an explicit ASK IF tied to A4/A3 comparisons, but that doesn't apply to A6.
  Logic: No skip/show logic found. The scenario text is framing (instructions) not a conditional filter.
  Intent: Ask A6 to all qualified respondents (those who passed screener). No per-row show logic detected.
  Variables: Verified A6r1 exists in the datamap (categorical_select, values 1-4). Other A6r* variables also present.
  Action: pass - default base (banner cut + non-NA for A6r1) is sufficient; no additionalFilter required.
  Confidence: 0.95 - explicit absence of skip/show logic and variables present in datamap.

---

## Entry 48 - 08:14:25.087

**Action**: `add`

[a6_detail_A6r2] [a6_detail_A6r2]:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' was found for A6 in the questionnaire. A6 text asks respondents to assume a future state and rank treatment paths for their NEXT 100 patients with uncontrolled LDL-C who are not currently on lipid-lowering therapy — this is a hypothetical/instructional scenario, not a conditional screen.
  Logic: No skip/show logic detected. Related conditional patterns (e.g., 'ONLY SHOW THERAPY WHERE A3>0') appear elsewhere (A3a/A4a) but do not apply to A6/A6r2.
  Intent: A6 is asked to all qualified respondents (no per-row or table-level show condition). It's not piped or looped from an earlier select question.
  Variables: A6r2 exists in datamap (categorical_select, values 1-4). Using the default banner cut + non-NA will correctly restrict to respondents who provided a rank.
  Action: pass - no additionalFilter needed.
  Confidence: 0.95 - explicit absence of conditional instructions and variable exists in datamap.

---

## Entry 49 - 08:14:31.948

**Action**: `add`

[a6_detail_A6r3] a6_detail_A6r3:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A6 in the survey document. A6 appears as a standalone ranking question: "For your NEXT 100 patients with uncontrolled LDL‑C and not currently taking any lipid‑lowering therapy, please rank...".
  Logic: Question framing is hypothetical (NEXT 100 patients not currently on lipid‑lowering therapy) and is presented to respondents to consider; there is no conditional branch or 'ONLY SHOW' instruction tied to prior answers. No per-row show logic is indicated for A6 (unlike earlier questions A3/A4 which have explicit 'ONLY SHOW THERAPY WHERE A3>0' style rules).
  Intent: Ask all qualified respondents (those who reached Section A) to rank up to 4 treatment paths. Rows are NOT conditioned on other variables in the datamap.
  Variables: A6r1..A6r8 exist in the datamap; the table uses A6r3 which is present (categorical_select, values 1-4). Non-NA on A6r3 correctly identifies respondents who provided a rank for that row.
  Action: pass - default base (banner cut + non-NA) is sufficient; no additionalFilter needed.
  Confidence: 0.95 - clear absence of skip/show logic in survey; variables verified in datamap.

---

## Entry 50 - 08:14:35.942

**Action**: `add`

[a6_detail_A6r4] a6_detail_A6r4:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A6 in the questionnaire. A6 is presented directly after A5 with full question text; no base condition or 'ONLY SHOW' clause is present.
  Logic: A6 asks respondents to rank treatment paths for NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy. This is a hypothetical scenario but not conditional in the script.
  Intent: Ask all respondents (table-level question). No per-row show logic identified.
  Variables: A6r1..A6r8 exist in datamap (A6r4 is present and mapped). No conditional variables referenced for showing A6.
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter required.
  Confidence: 0.95 - clear absence of skip/show logic and matching datamap variables.

---

## Entry 51 - 08:15:00.212

**Action**: `add`

[a6_detail_A6r5] a6_detail_A6r5:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A6 in the questionnaire. A6 is presented as a hypothetical ranking task for 'NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid‑lowering therapy.'
  Logic: The patient subgroup is a framing for the question (a hypothetical/patient-focus scenario), not an explicit skip/show condition in the survey instrument.
  Intent: Ask all qualified respondents to rank their preferred treatment paths for that hypothetical patient subgroup.
  Variables: A6r5 exists in the datamap (categorical_select, values 1-4). No separate condition variables exist for showing/hiding A6.
  Action: pass - banner cut + non-NA is sufficient; no additional filter needed.
  Confidence: 1.0 - clear absence of skip/show logic and variables verified in datamap.

---

## Entry 52 - 08:15:44.004

**Action**: `add`

[a6_detail_A6r6] [a6_detail_A6r6]:
  Survey: Located A6 in the questionnaire. The A6 prompt frames a scenario for "NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid‑lowering therapy" and asks respondents to rank treatment paths. There is no explicit [ASK IF], [SHOW IF], or "Base:" instruction associated with A6 in the survey document.
  Logic: No skip/show logic found for the A6 question as a whole. Other questions (e.g., A3a, A4a) contain SHOW/ONLY SHOW rules tied to previous answers, but A6 has none.
  Intent: The designer intended A6 to be asked of all qualified respondents (those who passed the screener), asking them to imagine a NEXT‑100 patient scenario. This is a hypothetical/patient‑population framing, not a respondent filter.
  Variables: A6r6 exists in the datamap (A6r1..A6r8 present). There are no condition variables (e.g., A6_* conditionals) referenced for row-level display.
  Action: pass – banner cut + non‑NA base is sufficient. No additionalFilter required.
  Confidence: 0.95 – explicit absence of skip/show instructions and variables exist in datamap.

---

## Entry 53 - 08:15:51.561

**Action**: `add`

[a6_detail_A6r7] a6_detail_A6r7:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A6 in the questionnaire. A5 contains an explicit conditional ('ASK IF PRESCRIBING IN A4 is > or < A3 FOR ROWS 2, 3, OR 4') but that applies to A5 only.
  Logic: The A6 prompt instructs respondents to consider their NEXT 100 patients not currently taking lipid-lowering therapy — this is framing/hypothetical content, not a skip condition applied in the survey programming.
  Intent: A6 appears to be asked to all respondents who reach this section; there is no separate condition variable controlling whether A6 was shown.
  Variables: A6r1..A6r8 exist in the datamap; the table uses A6r7 which is present and coded 1-4 (ranks). There is no separate condition variable to filter by.
  Action: pass — banner cut + non-NA is sufficient; no additionalFilter needed.
  Confidence: 0.95 — explicit absence of show logic, datamap variables present and consistent.
  Notes: Leave baseText empty so Excel will show 'All respondents'. No split or NET removal required.

---

## Entry 54 - 08:16:00.675

**Action**: `add`

[a6_detail_A6r8] a6_detail_A6r8:
  Survey: Reviewed A6 in questionnaire. No explicit [ASK IF] or [SHOW IF] instructions found for A6. The question frames a hypothetical: "For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid‑lowering therapy, please rank..." — this is scenario framing, not a respondent-level filter.
  Logic: None. A4/A5 include conditional logic elsewhere (e.g., A3/A4 feed-forward), but A6 has no ASK/SHOW clause in the survey document.
  Intent: Ask all qualified respondents to rank treatment paths for a hypothetical patient subgroup (NEXT 100 patients not on lipid-lowering therapy). The instruction does not limit which respondents are asked.
  Variables: A6r1..A6r8 exist in the datamap as categorical_select variables (allowed values 1-4 for rank positions). A6r8 (Other) exists. Verified variable names present in datamap.
  Action: pass — default base (banner cut + non-NA values) is sufficient; no additionalFilter needed.
  Confidence: 0.95 — explicit absence of skip/show logic and variables exist in datamap.
  Notes: No need to split; rows all reference the same A6 variable and share the same base. filterReviewRequired: false, humanReviewRequired: false.


---

## Entry 55 - 08:16:39.643

**Action**: `add`

[a6_rank1] a6_rank1:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A6 in the questionnaire. A6 is a hypothetical ranking question for 'NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy.'
  Logic: No skip/show instructions present near A6. Unlike other items (e.g., A3a/A4a which include 'ONLY SHOW THERAPY WHERE A3>0' / 'ONLY SHOW THERAPY WHERE A4>0'), A6 contains no conditional phrasing.
  Intent: Ask the ranking question to all respondents (respondents should rank treatment paths for the hypothetical NEXT 100 patients). This is a general/hypothetical instruction, not a filter based on prior answers.
  Variables: A6r1..A6r7 exist in the datamap as categorical_select with values 1-4. A6r8 exists (Other); datamap shows a constrained value but the variable is present. Therefore no needed additional variables for filtering.
  Action: pass - default base (banner cut + non-NA) is sufficient. No additionalFilter required.
  Confidence: 0.95 - explicit absence of skip/show logic; variables exist in datamap.
  Note: If downstream reviewers believe A6 should be shown only to respondents with a particular prior response, there is no explicit instruction in the survey; flagging not required.

---

## Entry 56 - 08:16:45.216

**Action**: `add`

[a6_top2_comparison] a6_top2_comparison:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A6. A6 asks respondents to 'assume' a future state and to rank treatment paths for their NEXT 100 patients who are not currently on lipid‑lowering therapy — this is a hypothetical patient-level frame, not a respondent-level filter.
  Logic: No skip/show instructions surrounding A6. Related conditional logic earlier ("ASK IF PRESCRIBING IN A4 is > or < A3...") applies to A5 only. A4 follow-ups have row-level show logic (ONLY SHOW THERAPY WHERE A4>0) but A6 has none.
  Intent: Ask all qualified respondents (i.e., those who reached this section) to rank — everyone asked, no additional respondent filter.
  Variables: A6r1..A6r8 exist in datamap as categorical_select (values 1-4) — appropriate for ranking/top-2 derivation.
  Action: pass - default base (banner cut + non-NA) is sufficient. No additionalFilter needed.
  Confidence: 0.95 - explicit absence of skip/show logic and variables exist in datamap.
  Notes: BaseText left blank (All respondents who reached the question). No split required.


---

## Entry 57 - 08:16:57.079

**Action**: `add`

[a7] [a7]:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A7 in the questionnaire. A7 appears after A6 and is presented with "RANDOMIZE" but no conditional instruction.
  Logic: A7 is a select-all-that-apply question asked to the continuing/qualified respondents (those who passed screener). No item-level show logic or per-row condition is indicated.
  Intent: Ask all qualified respondents how the indication change would impact perceptions/prescribing.
  Variables: A7r1, A7r2, A7r3, A7r4, A7r5 exist in the datamap as binary_flag variables. _NET_A7_AnyImpact is a derived NET of those components.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter needed.
  Confidence: 0.95 - explicit absence of conditional logic and variables verified in datamap.


---

## Entry 58 - 08:17:23.242

**Action**: `add`

[a8] a8:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A8 in the questionnaire. A8 appears in Section A with instructions to "RANDOMIZE ROWS; SHOW CAROUSEL LOOP FOR EACH OF THE THREE PRODUCTS (REPATHA, PRALUENT, LEQVIO)" but no conditional showing based on prior answers.
  Logic: The question is presented as a flat grid/carousel for three products across five patient situations. There is no survey instruction to limit this question to a subset (e.g., only those who indicated prescribing a product in A3).
  Intent: Ask all qualified respondents (those who passed screener) to state likelihood for each product/situation.
  Variables: Verified existence of all A8 variables in datamap (A8r1c1, A8r1c2, A8r1c3, A8r2c1... A8r5c3). They are categorical_select variables with allowed values 1-5.
  Action: pass - default base (banner cut + non-NA) is sufficient. No additionalFilter required.
  Confidence: 1.0 - explicit absence of skip/show logic and datamap confirms variables exist for all respondents.
  Note: Other questions in the survey do include "ONLY SHOW THERAPY WHERE A3>0" logic, but that condition is not present for A8. Do not apply A3-based filters without explicit instruction.

---

## Entry 59 - 08:17:34.252

**Action**: `add`

[a8_r2_full] a8_r2_full:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A8 in the survey text. A8 appears under Section A and is introduced with instructions to focus on patients with uncontrolled LDL-C; no additional conditional gating is specified.
  Logic: A8 uses a carousel loop over three products (Repatha, Praluent, Leqvio) and randomized patient-situation rows. There is no instruction like "ONLY SHOW THERAPY WHERE A3>0" for A8 (that instruction appears for A3a/A4a but not for A8). No per-row show logic (e.g., based on A3r2 > 0) is mentioned.
  Intent: Ask all qualified respondents (who reached Section A) to rate likelihood for each product in each patient situation. The product carousel is a display mechanism, not a skip condition.
  Variables: A8r2c1, A8r2c2, A8r2c3 exist in the datamap as 1-5 scales. No corresponding condition variables are required.
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter needed.
  Confidence: 0.95 - explicit absence of skip/show logic and presence of variables in datamap.

---

## Entry 60 - 08:17:49.377

**Action**: `add`

[a8_r1_full] a8_r1_full:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A8 in the survey document. A8 instructs 'RANDOMIZE ROWS; SHOW CAROUSEL LOOP FOR EACH OF THE THREE PRODUCTS (REPATHA, PRALUENT, LEQVIO)'. There is no 'ONLY SHOW' or conditional tied to prior answers for A8.
  Logic: A8 appears to be asked to all qualified respondents (carousel across the three products). Unlike A3a/A4a which explicitly say 'ONLY SHOW THERAPY WHERE A3>0', A8 has no such restriction.
  Intent: Ask all respondents their likelihood to prescribe each product (per patient situation).
  Variables: A8r1c1, A8r1c2, A8r1c3 exist in the datamap and correspond to the three product rows.
  Action: pass - default base (banner cut + non-NA for each A8 variable) is sufficient.
  Confidence: 0.95 - absence of any skip/show instructions is clear; variables verified in datamap.


---

## Entry 61 - 08:18:27.306

**Action**: `add`

[a8_r3_full] a8_r3_full:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A8 in the questionnaire. A8 is presented as a carousel loop for each of the three products (Repatha, Praluent, Leqvio) across patient situations. No "ONLY SHOW" or base instruction appears for A8 rows.
  Logic: A8 is asked to all qualified respondents (no per-product or per-row show logic). Adjacent questions (A3a/A4a) have conditional displays ("ONLY SHOW THERAPY WHERE A3>0"), but A8 does not.
  Intent: Ask all respondents to rate each product across patient situations.
  Variables: A8r3c1, A8r3c2, A8r3c3 exist in the datamap as categorical_select (1-5). Verified.
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter needed.
  Confidence: 0.95 - explicit absence of show logic; variables exist.
  Notes: No split required; NET rows are valid because all three product items share the same respondent pool (asked to all).

---

## Entry 62 - 08:18:43.647

**Action**: `add`

[a8_r4_full] a8_r4_full:
  Survey: Located question A8 in survey (Section A). No '[ASK IF]' or '[SHOW IF]' found for A8. Instructions: 'RANDOMIZE ROWS; SHOW CAROUSEL LOOP FOR EACH OF THE THREE PRODUCTS (REPATHA, PRALUENT, LEQVIO)'.
  Logic: No explicit skip/show logic limiting who sees A8. The carousel loop shows separate product screens but does not indicate respondents are screened by prior responses.
  Intent: Ask all eligible respondents (those past screener) about likelihood to prescribe each product in each patient situation.
  Variables: A8r4c1, A8r4c2, A8r4c3 exist in datamap with allowed values 1-5. No separate condition variables (e.g., A3r2>0) referenced for A8.
  Action: pass - default base (banner cut + non-NA on A8 variables) is sufficient. No additionalFilter required.
  Confidence: 0.95 - explicit absence of show logic; datamap variables exist.
  Notes: Other questions in this survey (A3a/A4a) include 'ONLY SHOW THERAPY WHERE A3>0' logic; A8 does not include this. Therefore do not apply A3-based filters to A8. No split required.


---

## Entry 63 - 08:18:58.388

**Action**: `add`

[a8_r5_full] a8_r5_full:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A8 in the survey. A8 lists patient situations a-e (including e: 'Who are intolerant of statins') and instructs to randomize rows and loop products; no skip logic present.
  Logic: A8 is presented to all respondents (within the qualified sample); no per-row SHOW conditions like "ONLY SHOW ROWS WHERE A3>0" are present.
  Intent: Ask all (qualified) respondents their likelihood to prescribe each product in each patient situation. A8r5 (intolerant of statins) is therefore asked of everyone.
  Variables: A8r5c1, A8r5c2, A8r5c3 exist in datamap with allowed values 1-5.
  Action: pass - default base (banner cut + non-NA for the variable) is sufficient. No additionalFilter needed.
  Confidence: 0.95 - explicit absence of skip/show logic; variables verified in datamap.

---

## Entry 64 - 08:19:27.781

**Action**: `add`

[a9] a9:
  Survey: No explicit [ASK IF] or [SHOW IF] instruction found for A9 in the survey document. I reviewed Section A around A8-A10. A3/A3a/A4/A4a contain 'ONLY SHOW THERAPY WHERE A3>0' instructions for related follow-ups, but A9 does not include any such conditional instruction.
  Logic: A9 asks about issues encountered when prescribing each product without a statin today. The response options include 'Haven't prescribed without a statin' (value=4), which means non-prescribers can select that option rather than being skipped.
  Intent: The designer intended to ask A9 of all respondents (per-product responses allowed), not to filter to only those who've prescribed without a statin.
  Variables: A9c1, A9c2, A9c3 exist in the datamap as categorical_select (values 1-4). Verified.
  Action: pass — banner cut + non-NA is sufficient. No additionalFilter or split required.
  Confidence: 0.95 — absence of show logic is explicit and variables exist in datamap.

---

## Entry 65 - 08:19:35.074

**Action**: `add`

[a8_t2b_by_situation] [a8_t2b_by_situation]:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A8 in the questionnaire. A8 appears under Section A and is presented to qualified respondents with instructions to 'RANDOMIZE ROWS; SHOW CAROUSEL LOOP FOR EACH OF THE THREE PRODUCTS (REPATHA, PRALUENT, LEQVIO)'.
  Logic: A8 asks respondents how likely they would be to prescribe each product alone across five patient situations. There are no conditional display rules tied to prior responses (e.g., A3>0) for A8. The matrix is requested for each product, independent of whether the respondent currently prescribes it.
  Intent: Ask all qualified respondents about prescribing likelihood for each product/situation (table-level question asked to all), not a follow-up shown only to specific respondents.
  Variables: A8r1c1, A8r1c2, A8r1c3, A8r2c1, A8r2c2, A8r2c3, A8r3c1, A8r3c2, A8r3c3, A8r4c1, A8r4c2, A8r4c3, A8r5c1, A8r5c2, A8r5c3 exist in the datamap as categorical_select (1-5). Verified.
  Action: pass - default base (banner cut + non-NA on each A8 variable) is sufficient; no additionalFilter required.
  Confidence: 0.95 - explicit absence of skip/show logic and variables present in datamap.
  Notes: Some other questions in Section A (e.g., A3a/A3b) include explicit 'ONLY SHOW THERAPY WHERE A3>0' logic, but A8 does not. Ensure downstream producers do not assume per-therapy usage filters for these A8 rows.

---

## Entry 66 - 08:20:01.370

**Action**: `add`

[a9_any_issues_comparison] a9_any_issues_comparison:
  Survey: Located question A9 in survey text. There is NO explicit [ASK IF] or [SHOW IF] before A9. A9 lists Repatha, Praluent, Leqvio and asks "To what extent have you encountered any issues... for using each of the following without a statin today? SELECT ONE FOR EACH COLUMN". Response options include "Haven’t prescribed without a statin" (value 4).
  Logic: No skip/show logic found. The presence of the "Haven’t prescribed without a statin" option indicates the question was intended to be asked to all respondents and capture non-prescribers rather than filter them out.
  Intent: Ask the whole (qualified) sample about issues encountered for each product; not restricted to users or prescribers.
  Variables: A9c1, A9c2, A9c3 exist in the datamap as categorical_select (values 1-4). Verified.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter needed.
  Confidence: 0.95 - explicit absence of show/ask logic and option to indicate non-prescribing.
  Notes: NET rows (filterValue "2,3") are valid because they simply compute percent of respondents selecting Some or Significant issues among all respondents who answered that product's question. No split or NET removal required.

---

## Entry 67 - 08:20:33.832

**Action**: `add`

[a9_praluent_detail] a9_praluent_detail:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for A9 in the questionnaire. A9 is presented as a matrix for each product (Repatha, Praluent, Leqvio) with response options including '4 = Haven't prescribed without a statin'.
  Logic: Question appears to be asked to all respondents (product carousel/looping used for display), not conditionally shown only to prescribers. The presence of the explicit 'Haven't prescribed without a statin' response implies the question is intended for everyone.
  Intent: Ask all respondents to report issues encountered when prescribing each product without a statin today.
  Variables: A9c2 exists in the datamap as categorical_select with allowed values 1-4.
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter needed.
  Confidence: 0.95 - explicit absence of show logic and variable exists in datamap.

---

## Entry 68 - 08:21:01.852

**Action**: `add`

[a9_repatha_detail] [a9_repatha_detail]:
  Survey: No explicit skip/show logic found for A9 in the questionnaire. A9 appears as a 3-column question (Repatha, Praluent, Leqvio) with no preceding [ASK IF] or [SHOW IF].
  Logic: A9 asks "To what extent have you encountered any issues... for using each of the following without a statin today?" Response option 4 is "Haven't prescribed without a statin", so non-prescribers are captured via a valid coded response rather than being skipped.
  Intent: Ask all respondents about issues encountered for each product; allow respondents to indicate they haven't prescribed without a statin.
  Variables: A9c1 exists in the datamap (allowed values 1-4). No condition variable (e.g., A3r2>0) is referenced for showing A9.
  Action: pass - no additional filter required; the default base (banner cut + non-NA of A9c1) is appropriate.
  Confidence: 1.0 - explicit absence of show/ask logic and variable exists in datamap.

---

## Entry 69 - 08:21:19.681

**Action**: `add`

[a9_leqvio_detail] a9_leqvio_detail:
  Survey: Reviewed A9 in survey document. No '[ASK IF]' or '[SHOW IF]' around A9. A9 asks: 'To what extent have you encountered any issues... for using each of the following without a statin today? SELECT ONE FOR EACH COLUMN' with products Repatha, Praluent, Leqvio.
  Logic: No explicit skip/show logic found. Response code 4 = 'Haven't prescribed without a statin' exists, indicating non-prescribers can respond using that option rather than being skipped.
  Intent: A9 appears to be a question asked to all respondents about their experience; answer options include 'Haven't prescribed without a statin' to capture those without experience.
  Variables: Datamap contains A9c1, A9c2, A9c3. A9c3 exists and allows values 1-4. Variable verified.
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter required.
  Confidence: 0.95 - explicit absence of skip/show logic & presence of explicit 'Haven't prescribed' response option in datamap.


---

## Entry 70 - 08:21:32.403

**Action**: `add`

[b1_binned] b1_binned:
  Survey: No [ASK IF] or [SHOW IF] found for B1 in survey document. B1 appears in Section B (Classification Information) asked to all respondents who qualified and reached this section.
  Logic: Question asks respondents to allocate percentages across insurance types that should sum to 100%. There is no conditional display per insurance type or per respondent.
  Intent: Ask all qualified respondents for percent of patients by insurance type. No per-row show logic.
  Variables: B1r1 through B1r8 exist in the datamap (Confirmed). No separate condition variables exist for individual rows.
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 - explicit absence of skip/show logic and variables exist in datamap.
  Note: Some earlier screener logic determines who reaches Section B (qualification), but that is handled by the pipeline's banner cut; no additionalFilter required.

---

## Entry 71 - 08:21:55.960

**Action**: `add`

[b1_mean] b1_mean:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for B1 in the survey document. B1 appears in Section B as a general classification question.
  Logic: B1 is asked to all respondents who reach Section B. There is no per-row or table-level skip/show logic. (Note: B4 contains an '[IF S2=1-5 SHOW]' but that applies only to B4, not B1.)
  Intent: Ask to all qualified respondents (no additional restrictions beyond the standard banner cut / qualification logic).
  Variables: B1r1-B1r8 exist in the datamap (confirmed). These are percentage allocations (0-100) and are valid non-NA values.
  Action: pass - default base (banner cut + non-NA) is sufficient. No additionalFilter needed.
  Confidence: 1.0 - explicit absence of skip/show logic; variables verified in datamap.

---

## Entry 72 - 08:21:59.898

**Action**: `add`

[a10] a10:
  Survey: No explicit [ASK IF] or [SHOW IF] found for A10 in the questionnaire. A10 appears immediately after A9 and has no conditional wording.
  Logic: The question includes an explicit response option A10r6 = "Haven't prescribed PCSK9s without a statin", which indicates the question was asked to all respondents (non-prescribers can indicate they haven't prescribed).
  Intent: Ask all respondents (who passed screener) to indicate reasons, including an explicit "haven't prescribed" option.
  Variables: A10r1-A10r6 exist in datamap as binary_flag variables (0/1).
  Action: pass - no additional filter. The default base (banner cut + non-NA) is appropriate because there is no show/skip logic in the survey that limits who was asked A10. Analysts who want a "reasons among prescribers" view should explicitly filter to A10r6 == 0, but that is a reporting choice, not a survey-enforced skip.
  Confidence: 0.95 - explicit lack of skip/show and presence of "haven't prescribed" response.


---

## Entry 73 - 08:22:20.880

**Action**: `add`

[b3] [b3]:
  Survey: No skip/show logic found for B3. In the questionnaire B3 is placed in Section B: "Which of the following best describes where your primary practice is located?" with no [ASK IF] or [SHOW IF] instruction. It appears under "ASK ALL" in Section B.
  Logic: Asked to all respondents who progressed to Section B (no conditional display tied to earlier responses).
  Intent: Ask all qualified respondents for their practice location.
  Variables: B3 exists in the datamap as categorical_select (allowed values 1-3: Urban, Suburban, Rural).
  Action: pass — default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 — explicit ASK ALL and variable present in datamap.
  Notes: B4 has a conditional [IF S2=1-5 SHOW], but that does not apply to B3. No per-row show logic or NET invalidity issues.


---

## Entry 74 - 08:22:52.589

**Action**: `add`

[b4] b4:
  Survey: Found B4 in Section B. The survey text includes: "B4. How many physicians [IF S2=1-5 SHOW:, including yourself,] are in your practice? [NUMERICAL OPEN END. ALLOW 1-9999 IF S2=1-5; ALLOW 0-9999 IF S2=6,7]". Datamap contains variable B4.
  Logic: The bracketed instruction modifies the question label and allowed response range by respondent role (S2), but does not include an [ASK IF] or [SHOW IF] that would prevent entire question from being shown to some respondents. Thus the question is presented to continuing respondents regardless of S2; wording and allowed min differ.
  Intent: Ask the numeric question to all continuing respondents (classification info). No table-level filter needed.
  Variables: B4 exists in datamap; S2 exists but is not required for filtering.
  Action: pass - default base (banner cut + non-NA B4) is sufficient.
  Confidence: 0.95 - explicit conditional is label/allowed-range only, not an ASK/SHOW that restricts who was asked.

---

## Entry 75 - 08:23:04.387

**Action**: `add`

[b4_binned] b4_binned:
  Survey: B4 appears in the survey with the inline instruction: '[ASK IF S2=1-5 SHOW: , including yourself,] ... [ALLOW 1-9999 IF S2=1-5; ALLOW 0-9999 IF S2=6,7]'.
  Logic: This controls wording and allowable numeric minimums depending on specialty (S2), not whether the question is asked at all. There is no '[ASK IF S2=...]' that restricts the entire question only to a subset.
  Intent: Ask the question to all respondents; show the phrase 'including yourself' only when S2 is 1-5 and allow a minimum of 1 in that case; for S2=6,7 the allowed min may be 0 (NP/PA could have 0 physicians).
  Variables: B4 exists in datamap (numeric range). S2 exists in datamap. No per-row condition variables exist that would require splitting.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter needed.
  Confidence: 0.95 - clear from survey text that wording/allowed range changes by S2 but the question itself is not limited to a subgroup.
  Note: NET (multi-physician) is valid because B4 responses come from same question (same denominator).

---

## Entry 76 - 08:23:33.136

**Action**: `add`

[qcard_specialty] qcard_specialty:
  Survey: S2 (What is your primary specialty?) is marked [ASK ALL] in the survey. No [ASK IF] / [SHOW IF] or base restriction is applied to S2 itself. Subsequent questions (S3a, S2a, S4) are conditional on S2 responses but do not restrict S2.
  Logic: None - S2 is asked to all respondents (subject to screener terminations applied earlier in banner cut).
  Intent: Ask to all respondents; grouping variable qCARD_SPECIALTY is a collapsed version of the full specialty list.
  Variables: qCARD_SPECIALTY exists in the datamap (categorical_select values 1-2). Verified.
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 - explicit ASK ALL in survey, variable exists.


---

## Entry 77 - 08:23:44.300

**Action**: `add`

[qcard_specialty] qcard_specialty:
  Survey: S2 "What is your primary specialty/role?" is under [ASK ALL] in the screener. There is branching after S2 (S2a, S3a, S4) that depends on S2 responses, but S2 itself is asked to all respondents (no [ASK IF]/[SHOW IF] limiting who sees S2).
  Logic: No skip/show logic applies to the entire question. The datamap contains qCARD_SPECIALTY (grouped variable collapsing original specialties into CARD vs NEPH/ENDO/LIP).
  Intent: Ask the specialty question of all respondents; grouping is a post-collection recode, not a show/skip condition.
  Variables: qCARD_SPECIALTY exists in the datamap. The original S2 exists as S2 in datamap. No additional condition variables are required.
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.00 - explicit [ASK ALL] for S2; grouping is derivation only.

---

## Entry 78 - 08:23:33.268

**Action**: `add`

[b5] b5:
  Survey: Evidence indicates B5 is only asked to respondents whose primary specialty was Internal Medicine / General Practitioner / Primary Care / Family Practice (S2=2). The table's existing baseText already states this.
  Logic: Table-level show logic: only respondents with S2==2 were asked B5.
  Intent: Ask only those who selected Internal Medicine / GP / PCP / Family Practice (table-level).
  Variables: S2 exists in datamap (categorical_select, values 1-99). Use S2 == 2 as the R expression.
  Action: filter - add additionalFilter "S2 == 2".
  BaseText: "Asked of respondents who indicated Internal Medicine / General Practitioner / Primary Care / Family Practice as their specialty"
  Confidence: 0.95 - survey flow and table baseText explicitly indicate this skip/show logic; variable exists in datamap.
  Notes: NET row is valid because all component rows share the same table-level base (S2==2). No split required.

---

## Entry 79 - 08:23:58.330

**Action**: `add`

[qconsent] qconsent:
  Survey: No explicit skip/show logic found for QCONSENT. It's presented in the FINAL SCREEN as a simple consent item.
  Logic: No [ASK IF], [SHOW IF], or Base: instruction around the CONSENT question. It's not conditional on any earlier response (other than reaching the end of the survey).
  Intent: Ask all respondents who completed the survey (i.e., no extra filter beyond standard banner cut & non-NA).
  Variables: QCONSENT exists in the datamap as categorical_select with values 1-2.
  Action: pass - default base (banner cut + non-NA) is sufficient.
  Confidence: 1.0 - clear, unconditional question at the end of the survey.
  Notes: Early termination rules in the screener (e.g., S1=3 or other terminations) are handled by the banner cut; they do not imply an extra per-question filter.

---

## Entry 80 - 08:24:30.175

**Action**: `add`

[qlist_tier] qlist_tier:
  Survey: No '[ASK IF]' or '[SHOW IF]' found for qLIST_TIER in the survey document. It is described as an administrative recruitment/list tier variable.
  Logic: No skip/show logic applies. This variable is assigned from the recruitment list and available for all respondents.
  Intent: qLIST_TIER is an administrative segmentation variable, not a follow-up question—asked/assigned to all respondents.
  Variables: qLIST_TIER exists in datamap (allowed values 1-4).
  Action: pass - default base (banner cut + non-NA) is sufficient; no additionalFilter needed. Table is already excluded as administrative (exclude: true).
  Confidence: 1.0 - explicit admin variable, no show/ask logic present.


---

## Entry 81 - 08:24:36.421

**Action**: `add`

[qlist_priority_account] qlist_priority_account:
  Survey: No explicit skip/show logic found in survey for qLIST_PRIORITY_ACCOUNT. This is an administrative recruitment tag mentioned in the survey header ("Will recruit from tagged list so will have segment assignments").
  Logic: None - variable is assigned as a sampling/administrative tag, not conditionally shown/asked via [ASK IF] or [SHOW IF].
  Intent: Record whether respondent came from the priority account list. Applies to all respondents (sampling metadata).
  Variables: qLIST_PRIORITY_ACCOUNT exists in datamap (values 1=PRIORITY, 2=NOT PRIORITY).
  Action: pass - banner cut + non-NA is sufficient; no additionalFilter needed. Note: table is already excluded from main report (exclude=true).
  Confidence: 1.00 - clear administrative variable with no skip/show logic.

---

## Entry 82 - 08:24:56.492

**Action**: `add`

[qlist_priority_account] qlist_priority_account:
  Survey: No '[ASK IF]' or '[SHOW IF]' or 'Base:' instruction found for qLIST_PRIORITY_ACCOUNT in the questionnaire. The survey notes 'Will recruit from tagged list so will have segment assignments' which indicates this is an administrative recruitment tag.
  Logic: qLIST_PRIORITY_ACCOUNT is an administrative/sample segmentation variable (priority vs not priority). It is not a follow-up question and there is no skip/show logic limiting who is asked.
  Intent: This variable marks which sample list the respondent came from; it applies to all cases in the dataset (assigned externally), not a conditional question.
  Variables: qLIST_PRIORITY_ACCOUNT exists in datamap (categorical_select, values 1=PRIORITY, 2=NOT PRIORITY).
  Action: pass - default base (banner cut + non-NA) is sufficient. No additionalFilter required. The table is already marked 'exclude' as an administrative tag.
  Confidence: 1.0 - explicit in survey and datamap; unambiguous.

---

## Entry 83 - 08:25:35.868

**Action**: `add`

[qon_list_off_list] qon_list_off_list:
  Survey: No explicit '[ASK IF]' or '[SHOW IF]' found for qON_LIST_OFF_LIST in the questionnaire. The variable appears to be a recruitment/list-membership tag (ON-LIST vs OFF-LIST) covering provider types.
  Logic: None found. S2 (specialty) has its own show logic for S2a/S3a, but nothing that restricts qON_LIST_OFF_LIST to a subset of respondents.
  Intent: qON_LIST_OFF_LIST records whether the respondent is on or off the recruitment list for their provider type. This is an overall screener/admin variable and should be available for all respondents.
  Variables: qON_LIST_OFF_LIST exists in the datamap with values 1-6 mapping to Card on/off, PCP on/off, NP/PA on/off.
  Action: pass - default base (banner cut + non-NA) is sufficient. No additionalFilter needed.
  Confidence: 1.00 - explicit absence of skip/show logic in the survey and datamap confirms variable exists for all respondents.

---

## Entry 84 - 08:25:45.339

**Action**: `add`

[qon_list_off_list_by_provider] qon_list_off_list_by_provider:
  Survey: No explicit [ASK IF] or [SHOW IF] found for qON_LIST_OFF_LIST in the questionnaire. The ON-LIST/OFF-LIST membership appears to be a recruitment/list membership attribute (recruitment list membership noted in userNote).
  Logic: No skip/show logic applies to this variable in the survey text. S2 contains branching for specialty (e.g., ASK S3a if S2=1, ASK S2a if S2=6 or 7), but qON_LIST_OFF_LIST is a separate categorical variable in the datamap (values 1-6) and is not shown/hidden by any [ASK IF].
  Intent: qON_LIST_OFF_LIST categorizes respondents by provider type and priority (on/off list) and is available for respondents in the sample; the table simply aggregates those categories.
  Variables: qON_LIST_OFF_LIST exists in the datamap with allowed values 1-6 (CARD ON-LIST, CARD OFF-LIST, PCP ON-LIST, PCP OFF-LIST, NPPA ON-LIST, NPPA OFF-LIST). Verified.
  Action: pass - default base (banner cut + non-NA on qON_LIST_OFF_LIST) is sufficient.
  Confidence: 0.95 - variable exists and no explicit show/ask logic found; low risk of hidden branching.

---

## Entry 85 - 08:25:59.670

**Action**: `add`

[qspecialty] qspecialty:
  Survey: S2 'What is your primary specialty/role?' is labeled [ASK ALL] in the screener. No [ASK IF] or [SHOW IF] gating this question itself.
  Logic: There are follow-up items (S3a asked if S2=1; S2a asked if S2=6 or 7) but these are follow-ups, not gating S2.
  Intent: Ask to all respondents; qSPECIALTY is a condensed variable mapping specialties into CARD/PCP/NPPA.
  Variables: qSPECIALTY exists in datamap (values 1-3). No other condition variables referenced.
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter needed.
  Confidence: 1.0 - question explicitly ASK ALL; variable exists in datamap; unambiguous.

---

## Entry 86 - 08:26:07.661

**Action**: `add`

[qon_list_off_list_on_vs_off] qon_list_off_list_on_vs_off:
  Survey: No explicit [ASK IF] or [SHOW IF] was found for qON_LIST_OFF_LIST in the questionnaire. The variable appears to be recruitment/sample membership (ON-LIST/OFF-LIST) and is present in the datamap with values 1-6.
  Logic: No skip/show logic around this question. It is a prepopulated/sample assignment variable describing priority account membership by specialty (Card, PCP, NP/PA).
  Intent: Record of recruitment list membership for all respondents (or pre-filled). Categories are simply values of one variable, not per-row show logic.
  Variables: qON_LIST_OFF_LIST exists in datamap (values 1-6). No related condition variables (ASK IF) were identified.
  Action: pass - default base (banner cut + non-NA) is sufficient. No additionalFilter needed.
  Confidence: 0.95 - explicit absence of show logic; variable is clearly a sample tag.

---

## Entry 87 - 08:26:28.960

**Action**: `add`

[qtype_of_card] qtype_of_card:
  Survey: Found '[ASK IF S2=1]' before question S3a in the survey document (S3a: "What type of Cardiologist are you primarily?").
  Logic: S3a is only asked to respondents who selected 'Cardiologist' at S2.
  Intent: Ask only those who are Cardiologists (table-level filter).
  Variables: S2 exists in datamap (categorical_select with 1=Cardiologist). qTYPE_OF_CARD exists and corresponds to this question. Use filter S2 == 1.
  Action: filter - add additionalFilter 'S2 == 1' so base includes only respondents who identified as Cardiologist.
  Confidence: 0.95 - explicit '[ASK IF S2=1]' present and variables exist in datamap.

---

## Entry 88 - 08:26:39.794

**Action**: `add`

[qtype_of_card_reference] qtype_of_card_reference:
  Survey: Found '[ASK IF S2=1]' controlling S3a (What type of Cardiologist are you primarily?)
  Logic: S3a is shown only to respondents who selected S2=1 (Cardiologist)
  Intent: Ask only respondents whose primary specialty is Cardiologist about their cardiologist type
  Variables: S2 exists in datamap (categorical_select, values include 1=Cardiologist). qTYPE_OF_CARD exists in datamap (values 1-3). 
  Action: filter - apply additionalFilter S2 == 1 so base reflects only Cardiologists. 
  Confidence: 0.95 - explicit ASK IF logic in survey and variables verified in datamap.
  Note: Table is marked excluded/reference; still setting the correct base for consistency in any derived stats.

---

## Entry 89 - 08:26:49.711

**Action**: `add`

[region] [region]:
  Survey: No explicit [ASK IF] or [SHOW IF] instructions found for Region. B2 (zip code) is asked to all respondents and includes hidden STATE and REGION derived fields.
  Logic: Region is a derived hidden variable based on main practice ZIP code (B2). There is no per-respondent skip/show filter for Region.
  Intent: Assign region to all respondents based on ZIP code; the question is not conditional.
  Variables: Region exists in datamap (values 1-6: Northeast, South, Midwest, West, Other, Invalid Region).
  Action: pass - banner cut + non-NA is sufficient. No additionalFilter needed.
  Confidence: 1.0 - explicit in survey and datamap; no ambiguity.


---

## Entry 90 - 08:27:26.921

**Action**: `add`

[us_state] us_state:
  Survey: No '[ASK IF]' or '[SHOW IF]' found for B2 or US_State. B2 (zip code) appears in Section B 'Classification Information' with no conditional instructions; it's a standard classification question asked to all respondents who reached this part of the survey.
  Logic: None - US_State is system-derived from B2 (zip). No per-row or table-level show logic.
  Intent: Ask all qualifying respondents to provide zip code; derive state for everyone.
  Variables: US_State exists in datamap; B2 exists (B2: zip code). Both are present and valid.
  Action: pass - default base (banner cut + non-NA) is sufficient; no additionalFilter required.
  Confidence: 1.00 - explicit absence of skip/show logic, variable exists in datamap.

---

## Entry 91 - 08:27:33.890

**Action**: `add`

[us_state_region] us_state_region:
  Survey: B2 (zip code of main practice location) is located in SECTION B: Classification Information and is asked to all respondents (ASK ALL). US_State is derived from B2.
  Logic: No [ASK IF] / [SHOW IF] or other skip logic found gating B2 or US_State. There are screener terminations earlier in the survey, but those are handled by the banner cut.
  Intent: US_State/B2 asked to all qualifying respondents (no per-row show logic).
  Variables: US_State exists in datamap (categorical_select 1-53). B2 exists in datamap (text_open).
  Action: pass - default base (banner cut + non-NA) is sufficient; no additionalFilter needed.
  Confidence: 0.95 - explicit ASK ALL and variable present; straightforward.
