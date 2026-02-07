# SkipLogicAgent Scratchpad Trace

Generated: 2026-02-07T02:34:24.400Z
Total entries: 1

---
## Entry 1 - 20:33:58.690

**Action**: `add`

[S1]: Found/No skip logic
  Text: ASK ALL. Options include TERMINATE for option 3.
  Type: none (screener termination not a rule).
  Applies to: S1
  Note: Termination directives do not create a rule because those respondents do not exist in data.

[S2]: Found/No skip logic
  Text: ASK ALL. Options include ASK S3a for option 1; CONTINUE TO S4 for option 2; ASK S2a for option 6; TERMINATE for 99.
  Type: none for S2 itself (asked to all). But creates visibility rules for S3a, S2a, S4.

[S2a]: Found skip logic
  Text: [ASK IF S2=6 OR 7]
  Type: table-level
  Applies to: S2a
  Condition: Respondent must have selected S2 = 6 or 7.

[S3a]: Found skip logic
  Text: [ASK IF S2=1]
  Type: table-level
  Applies to: S3a
  Condition: Respondent must have selected S2 = 1 (Cardiologist).

[S4]: Found skip logic
  Text: [ASK IF S2=1-5]
  Type: table-level
  Applies to: S4
  Condition: Respondent must have selected S2 in 1-5.

[S5]: ASK ALL; options include TERMINATE for some selections. No rule.

[S6-S12]: ASK ALL with termination conditions (<3 or >35, part-time, etc.) but these are screener terminations; no rule for post-screener questions.

[A1]: No ASK IF/SHOW IF. No rule.

[A2a/A2b]: No ASK IF. No rule.

[A3]: No ASK IF; collects counts.

[A3a]: Survey text: "ONLY SHOW THERAPY WHERE A3>0" and "RANDOMIZE IN SAME ORDER AS A3. ONLY SHOW THERAPY WHERE A3>0". This is row-level show logic.
  Type: row-level
  Applies to: A3a
  Condition: Show each therapy row only if corresponding A3 value > 0.

[A3b]: "ONLY SHOW ROWS FOR WHICH A3a COL B > 0". Row-level; shows rows only where in A3a the 'without a statin' column >0. Applies to A3b.

[A4]: No ASK IF; similar to A3.

[A4a]: "RANDOMIZE IN SAME ORDER AS A3. ONLY SHOW THERAPY WHERE A4>0" Row-level show per therapy where A4>0.

[A4b]: "ONLY SHOW ROWS FOR WHICH A4a COL B > 0" Row-level show where A4a without-statin col >0.

[A5]: "ASK IF PRESCRIBING IN A4 is > or < A3 FOR ROWS 2, 3, OR 4 (LEQVIO, REPATHA, OR PRALUENT)" Table-level: only ask if A4 differs from A3 for any of rows 2,3,4.

[A6]: No ASK IF; no rule.

[A7]: No ASK IF; no rule.

[A8]: Loop per product; no explicit gating; no rule.

[A9]: No ASK IF; per product; no rule.

[A10]: No ASK IF; no rule.

[B1-B4]: No explicit ASK IF except B4 has conditional text about input range depending on S2; visibility unchanged -> no rule.

[B5]: [ASK IF S2=2] -> table-level rule applies to B5.

[Other items: Consent and final screen not survey questions needing rules.]

Summary: Identified rules for S2a, S3a, S4, A3a (row-level), A3b (row-level), A4a (row-level), A4b (row-level), A5 (table-level), B5 (table-level). All other questions -> noRuleQuestions.
