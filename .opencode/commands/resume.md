Resume from the last saved session. Load the current project state and present where to continue.

## Steps

1. Read `.opencode/SESSION.md` — the full session history.

2. Extract and present:
   - **Active Chapter:** What feature is being worked on
   - **Last Session:** What was completed (with dates)
   - **Pending:** What's next to implement
   - **Blockers:** Any unresolved issues
   - **Key Decisions:** Important choices made in previous sessions

3. Ask the user: "Continue from here? Pick the next step:"

Present options:
   - [1] Continue the active chapter (next pending task)
   - [2] Review what was done last session
   - [3] Jump to a different pending task
   - [4] Start a new chapter (use /chapter-plan)

4. Based on user's choice, delegate to the right agent:
   - Backend work → `@spree-backend`
   - Storefront work → `@spree-storefront`

5. The delegated agent should read `.opencode/SESSION.md` and all `.opencode/memory/` files before starting.
