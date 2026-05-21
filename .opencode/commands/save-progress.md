Save the current session progress to the cross-session memory file.

Do the following:
1. Read `.opencode/SESSION.md` to see previous session entries
2. Analyze what was accomplished in this session:
   - What features/modules were worked on
   - What was implemented and tested
   - What decisions were made
   - What blockers were encountered
3. Write a new entry at the TOP of `.opencode/SESSION.md` (after the title line) in this format:

```
## YYYY-MM-DD — [Short Session Title]

### Active Chapter
[Which chapter/feature is in progress]

### Completed
- [x] [Specific thing implemented, with file paths]
- [x] [Tests written and passing]

### Decisions Made
- [Decision 1 — why, tradeoffs]
- [Decision 2]

### Pending
- [ ] [Next task to implement]
- [ ] [Blocked — why]

### Notes
[Any context useful for the next session]
```

4. Show the summary to the user
5. Ask: "Is this progress summary accurate?"
6. Only save after user confirms

Keep previous session entries below the new one. Do NOT delete old entries — they provide history.
