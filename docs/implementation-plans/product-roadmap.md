**Goal**: Support message testing surveys (and MaxDiff studies with utility scores) by allowing users to upload message lists that get integrated into the datamap.

**What's needed**:
- Intake question: "Does this survey include messages?" → upload message list
- Message file parsing (Excel preferred, Word supported)
- Datamap enrichment: link message text to question variables
- Agent awareness: VerificationAgent uses actual message text in table labels

**Level of Effort**: Medium. Prioritize post-MVP based on Antares feedback.

- extensive testing & record demo / setup antares schedule email
- still dont give user a clear sign after the review screen that it saved

verify cicd pipeline is workingß

- ensure output file name matches the downloadable file name