# SkipLogicAgent Scratchpad Trace

Generated: 2026-02-07T03:01:04.916Z
Total entries: 9

---
## Entry 1 - 20:58:04.728

**Action**: `add`

[S1]: Found/No skip logic
  Text: "Are you happy to proceed on this basis?" with options: 1 proceed and protect identity, 2 proceed and give permission to pass contact details if adverse event mentioned, 3 I don't want to proceed [TERMINATE]
  Type: none (ASK ALL)
  Applies to: S1
  Note: No ASK IF/SHOW IF; option 3 is termination (screener) which is not a rule because terminated respondents are not in data.

[S2]: Found/No skip logic
  Text: "What is your primary specialty/role? RANDOMIZE" with options 1 Cardio (ASK S3a), 2 Internal Medicine (CONTINUE TO S4), 3 Nephrologist, 4 Endocrinologist, 5 Lipidologist, 6 Nurse Practitioner (ASK S2a), 7 Physician's Assistant (ASK S2a), 99 Other (TERMINATE)
  Type: table-level branching for follow-ups
  Applies to: S2
  Note: S2 itself is ASK ALL; but it contains explicit directives to show follow-ups for certain responses. We'll create rules for the follow-up questions (S3a, S2a, S4) rather than for S2 itself.

---

## Entry 2 - 20:58:09.542

**Action**: `add`

[S2a]: Found skip logic
  Text: "[ASK IF S2=6 OR 7] S2a. In what type of doctor's office do you work?" Options: 1 Cardiologist (CONTINUE TO S4); 2 Internal Medicine / GP / Primary Care / Family Practice (TERMINATE); 3 Other (TERMINATE).
  Type: table-level
  Applies to: S2a
  Note: Explicit ASK IF S2=6 or 7 so S2a only shown to NPs/PAs. This is a rule: S2a is only asked if S2 in {6,7}. Also internal options 2 and 3 terminate respondents; termination means those respondents won't be in data, but the rule identifying S2a base is valid because S2a was only asked to NP/PA respondents.

[S3a]: Found skip logic
  Text: "[ASK IF S2=1] S3a. What type of Cardiologist are you primarily?" Options: 1 Interventional, 2 General, 3 Preventative. [INFORMATIONAL, TRACK DURING FIELDING]
  Type: table-level
  Applies to: S3a
  Note: Explicit ASK IF S2=1 so only cardiologists see S3a. This is a rule.

[S4]: Found skip logic
  Text: "[ASK IF S2=1-5] S4. Are you currently board certified or eligible in your specialty? Board Eligible [TERMINATE]; Board Certified; Neither [TERMINATE]"
  Type: table-level
  Applies to: S4
  Note: Explicit ASK IF S2 in 1-5 so S4 only asked to physicians (cardio, internal med, nephro, endocr, lipidologist). Responses Board Eligible and Neither cause termination (screener), but that's part of initial qualification. But the key rule is S4 is only asked if S2 in 1-5.

---

## Entry 3 - 20:58:12.101

**Action**: `add`

[S5]: Found/No skip logic
  Text: "S5. Are you or is any member of your family currently employed by, or have a commercial affiliation with any of the following? Select all that apply. (List includes Marketing firm, Pharma manufacturer, Govt regulatory agency, Advertising Agency, etc.) Options other than 'None of these' indicate TERMINATE."
  Type: table-level (screener)
  Applies to: S5
  Note: This is a screener question with termination for many responses; but per instructions, termination conditions are not rules because terminated respondents not in dataset. However, S5 is still ASK ALL and no further post-screener branching is indicated. So S5 is noRuleQuestions.

---

## Entry 4 - 20:58:18.094

**Action**: `add`

[S6]: Found/No skip logic
  Text: "S6. How many years have you been in clinical practice? (TERMINATE IF <3 OR >35)"
  Type: table-level (screener)
  Applies to: S6
  Note: Screener termination; not a rule for post-qualification. So S6 is noRuleQuestions.

[S7]: Found/No skip logic
  Text: "S7. Are you practicing full-time (1) or part-time (2) (TERMINATE if part-time)"
  Type: table-level (screener)
  Applies to: S7
  Note: Screener termination; not a rule. S7 is noRuleQuestions.

[S8]: Found/No skip logic
  Text: "S8. Percentage of professional time for tasks A-D; MUST SPEND AT LEAST 70% ON S8A ELSE TERMINATE"
  Type: table-level (screener)
  Applies to: S8
  Note: Screener termination; not a rule. S8 is noRuleQuestions.

[S9]: Found/No skip logic
  Text: "S9. Which of the following best represents the setting in which you spend most of your professional time? Options 1-7 (VA Hospital 7 = TERMINATE), 8 None of the above"
  Type: table-level (screener)
  Applies to: S9
  Note: Screener termination; not a rule. S9 is noRuleQuestions.

[S10]: Found/No skip logic
  Text: "S10. How many adult patients do you personally manage per month? (TERMINATE IF <50)"
  Type: table-level (screener)
  Applies to: S10
  Note: Screener termination; not a rule. S10 is noRuleQuestions.

[S11]: Found/No skip logic
  Text: "S11. Of those adult patients, roughly how many have confirmed hypercholesterolemia with established CVD? (ALLOW 0-S10). TERMINATE IF <10"
  Type: table-level (screener)
  Applies to: S11
  Note: Screener termination; not a rule. S11 is noRuleQuestions.

[S12]: Found/No skip logic
  Text: "S12. Of those, how many patients have had an event (MI, CAD, etc.) Over 5 years ago; Within last 3-5 yrs; Within 1-2 yrs; Within last year. TERMINATE IF D = 0. AUTO-SUM. SUM MUST BE <= S11"
  Type: table-level (screener)
  Applies to: S12
  Note: Screener termination; not a rule. S12 is noRuleQuestions.

---

## Entry 5 - 20:58:20.756

**Action**: `add`

[A1]: Found/No skip logic
  Text: "A1. To the best of your knowledge, which statement below best describes the current indication for each of the following treatments? Check one box per row. (List: Leqvio, Praluent, Repatha, Nexletol)
  Type: table-level
  Applies to: A1
  Note: No ASK IF or Base: instructions. It's an awareness/knowledge grid asked to all qualified respondents. Default base likely sufficient. So no rule.

---

## Entry 6 - 20:58:23.589

**Action**: `add`

[A2a]: Found/No skip logic
  Text: "A2a. To the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation regarding lipid-lowering?" (List of 3 options)
  Type: table-level
  Applies to: A2a
  Note: No ASK IF; shown to all. No rule.

[A2b]: Found/No skip logic
  Text: "A2b. And to the best of your knowledge, which of the following best describes the current post-ACS guideline recommendation specific to lipid-lowering therapy?" (3 options)
  Type: table-level
  Applies to: A2b
  Note: No ASK IF; shown to all. No rule.

---

## Entry 7 - 20:58:28.839

**Action**: `add`

[A3]: Found/No skip logic
  Text: "A3. For your LAST 100 patients with uncontrolled LDL-C, please indicate for how many you prescribed each of the following therapies? Your answer can add to greater than 100. List includes Statin only (anchor), Leqvio, Praluent, Repatha, Zetia, Nexletol, Other." Randomize 2-6.
  Type: table-level
  Applies to: A3
  Note: No ASK IF or Base; shown to all qualified respondents. Default base likely sufficient. No rule.

[A3a]: Found skip logic (row-level)
  Text: "A3a. For each treatment, approximately what % of those LAST 100 patients received that therapy in addition to a statin vs. without a statin? Each row must add to 100%. RANDOMIZE IN SAME ORDER AS A3. ONLY SHOW THERAPY WHERE A3>0"
  Type: row-level
  Applies to: A3a
  Plain: Show each therapy row only if respondent entered A3>0 for that therapy. So row-level gating depends on corresponding A3 row being >0.
  Note: This is explicit: ONLY SHOW THERAPY WHERE A3>0. We'll create a row-level rule referencing A3.

[A3b]: Found skip logic (row-level)
  Text: "A3b. For each treatment you just indicated that you prescribe without a statin, approximately what % of those patients who received that therapy without a statin did so… ONLY SHOW ROWS FOR WHICH A3a COL B > 0"
  Type: row-level
  Applies to: A3b
  Plain: Show each therapy row only if in A3a the respondent entered a non-zero % in column B (without a statin) for that therapy (i.e., A3a COL B > 0).
  Note: Explicit show logic referencing A3a. Create rule.

---

## Entry 8 - 20:58:42.755

**Action**: `add`

[A4]: Found/No skip logic
  Text: "A4. Now please assume that the FDA decides that all PCSK9is (Repatha, Praluent, Leqvio) will... In that future state, for your NEXT 100 patients with uncontrolled LDL-C, for how many would you prescribe each of the following treatments? Your responses from previous question are included for reference. RANDOMIZE IN SAME ORDER AS A3."
  Type: table-level
  Applies to: A4
  Note: No ASK IF/SHOW IF; shown to all. No rule.

[A4a]: Found skip logic (row-level)
  Text: "A4a. For each treatment, for approximately what % of those NEXT 100 patients would you expect to prescribe that therapy in addition to a statin vs. without a statin? Each row must add to 100%. RANDOMIZE IN SAME ORDER AS A3. ONLY SHOW THERAPY WHERE A4>0"
  Type: row-level
  Applies to: A4a
  Plain: Only show therapy rows where A4>0 (i.e., respondent entered a non-zero count in A4 for that therapy). This is explicit.

[A4b]: Found skip logic (row-level)
  Text: "A4b. For each treatment you just indicated that you would expect to prescribe without a statin, approximately what % of those patients who would receive that therapy without a statin would do so… ONLY SHOW ROWS FOR WHICH A4a COL B > 0"
  Type: row-level
  Applies to: A4b
  Plain: Show rows only where A4a column B > 0.

[A5]: Found skip logic (table-level)
  Text: "[ASK IF PRESCRIBING IN A4 is > or < A3 FOR ROWS 2, 3, OR 4 (LEQVIO, REPATHA, OR PRALUENT)] A5. How quickly might you expect to change your prescribing of PCSK9 inhibitors based on this indication change?"
  Type: table-level
  Applies to: A5
  Plain: Only ask A5 if change in prescribing in A4 compared to A3 for Leqvio, Repatha, or Praluent (rows 2,3,4) i.e., A4 > A3 or < A3? The parenthetical says "is > or < A3" meaning if A4 differs from A3 for any of those rows. This is explicit but slightly ambiguous. We'll record it as table-level dependent on whether respondent's A4 value differs from A3 for any of rows 2,3,4.

[A6]: Found/No skip logic
  Text: "A6. Again, please assume... For your NEXT 100 patients with uncontrolled LDL-C and not currently taking any lipid-lowering therapy, please rank which treatment paths you might be most likely to follow? You can rank your top 4 paths." (list)
  Type: table-level
  Applies to: A6
  Note: No ASK IF. Shown to all respondents (unless elsewhere). No rule.

[A7]: Found/No skip logic
  Text: "A7. How might being able to use PCSK9 inhibitors indicated for use with or without statin therapy impact your perceptions and/or prescribing? Select all that apply." (list)
  Type: table-level
  Applies to: A7
  Note: No ASK IF. No rule.

[A8]: Found/No skip logic (but row-level show?)
  Text: "A8. For each patient situation, how likely would you be to prescribe each of the following therapies alone (i.e., without a statin...)? [INSERT PRODUCT NAME]. RANDOMIZE ROWS; SHOW CAROUSEL LOOP FOR EACH OF THE THREE PRODUCTS (REPATHA, PRALUENT, LEQVIO). Rows a-e: patients with established CVD etc."
  Type: table-level (with per-product carousel loop)
  Applies to: A8
  Note: No explicit ASK IF or ONLY SHOW. The carousel suggests each product is shown in a loop but not gated by prior answers. So default base likely sufficient. No rule.

[A9]: Found/No skip logic
  Text: "A9. To what extent have you encountered any issues with coverage, approvals, cost, etc. for using each of the following without a statin today? SELECT ONE FOR EACH COLUMN. Repatha, Praluent, Leqvio."
  Type: table-level
  Applies to: A9
  Note: No explicit gating. No rule.

[A10]: Found/No skip logic
  Text: "A10. For what reasons are you using PCSK9 inhibitors without a statin today? Select all that apply. Options include patient failed statins prior to starting PCSK9i; statin intolerant; patient refused statins; contraindicated; not or unlikely to be compliant; Haven't prescribed PCSK9s without a statin [ANCHOR]"
  Type: table-level
  Applies to: A10
  Note: No explicit ASK IF/SHOW IF. One option is 'Haven't prescribed PCSK9s without a statin' which is a response that could be recorded; but no gating instructions provided. So no rule.

---

## Entry 9 - 20:58:50.813

**Action**: `add`

[B1]: Found/No skip logic
  Text: "B1. What percentage of your current patients are covered by each type of insurance? (A Not insured; B Private; C Traditional Medicare; D Traditional Medicare + supplemental; E Private Medicare; F Medicaid; G VA; H Other) TOTAL MUST SUM TO 100%"
  Type: table-level
  Applies to: B1
  Note: No ASK IF. Shown to all. No rule.

[B2]: Found/No skip logic
  Text: "B2. What is the zip code of your main practice location? Zip code (INCLUDE HIDDEN STATE, REGION)"
  Type: table-level
  Applies to: B2
  Note: No ASK IF. No rule.

[B3]: Found/No skip logic
  Text: "B3. Which of the following best describes where your primary practice is located? 1 Urban, 2 Suburban, 3 Rural"
  Type: table-level
  Applies to: B3
  Note: No ASK IF. No rule.

[B4]: Found/No skip logic
  Text: "B4. How many physicians [IF S2=1-5 SHOW:, including yourself,] are in your practice? NUMERIC OPEN END. ALLOW 1-9999 IF S2=1-5; ALLOW 0-9999 IF S2=6,7"
  Type: table-level
  Applies to: B4
  Note: There's slight show logic for the label/display: the question wording changes if S2=1-5 to say 'including yourself'. But actual show/hide logic is not gating the question – it is asked to all. So no rule.

[B5]: Found skip logic
  Text: "[ASK IF S2=2] B5. How would you describe your specialty/training? Select all that apply. Options: Internal Medicine, GP, Primary Care, Family Practice, DO"
  Type: table-level
  Applies to: B5
  Plain: Only ask B5 if S2=2 (Internal Medicine / GP / Primary Care / Family Practice). Explicit rule.

[CONSENT]: Found/No skip logic
  Text: "CONSENT. If you would be willing to participate in future research to further elaborate on the responses from this survey, please indicate below: Yes / No"
  Type: table-level
  Applies to: CONSENT
  Note: No ASK IF. No rule.

[FINAL SCREEN]: Found/No skip logic
  Text: "Thank you for your time! You have completed the survey."
  Type: table-level
  Applies to: FINAL SCREEN
  Note: No rule.
