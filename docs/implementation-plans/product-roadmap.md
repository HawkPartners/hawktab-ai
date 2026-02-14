**Goal**: Support message testing surveys (and MaxDiff studies with utility scores) by allowing users to upload message lists that get integrated into the datamap.

**What's needed**:
- Intake question: "Does this survey include messages?" → upload message list
- Message file parsing (Excel preferred, Word supported)
- Datamap enrichment: link message text to question variables
- Agent awareness: VerificationAgent uses actual message text in table labels

**Level of Effort**: Medium. Prioritize post-MVP based on Antares feedback.

- extensive testing & record demo / setup antares schedule email
- still dont give user a clear sign after the review screen that it saved

- verify the CICD pipeline is working

- we need to debug easier, way more logs captured so we can actually trace; if cost is an issue we can just capture logs with errorts; but think through context graphs for agent decisions, etc.
better visual showing what we are analyzing for during data validation
bug where if the title of the project is long enough, it doesnt truncate, ultmately overlappign our time start estimate in the side bar
- be ready to define what loop groups are and why it may differ from the actual variables in the loop
rate limits and quotas
- more visuals to show the process as it goes what cuts were discovered)
- better dashbparding so i can track per project costs and errors above
- titos classified location as entity anchored but maybe we prefer respondent anchored? need a good grasp of this and try to make it configurable posts given its just how we want to analyze the data and doesnt require a new run

Start to think about strategy to move from Hawktab ai 

- no more saving input files, all processing should be done in the cloud, and purge all input files from the local machine and hawkpartners stuff

- FLAG importance of HOTL to users; also ensure agents provide human readable reasons for their interpretation of what the banner cuts mean in the context of the data. maybe they even provide a intelligent hint that can be pulled into the loop policy agent to provide a more intelligent suggestion. also maybe this is surfaced to the human reviiewer and ask them how should we handle this?

make HITL much more visible and just important, not a warning or scary but just important

flag loops to crosstab agent