Guide the user through chapter-by-chapter planning for a new feature or project phase.

## Steps

1. Ask the user: "What feature or project phase do you want to plan?"

2. Propose an initial chapter breakdown:
```
## Chapter Plan: [Feature Name]

### Ch1: [Chapter Name]
- Goal: [One sentence]
- DB changes: [Tables, columns, indexes, migrations needed]
- API endpoints: [New or modified endpoints]
- Storefront components: [New pages, components, server actions]
- Test plan: [What tests to write]
- Performance notes: [Caching, indexing, optimization]

### Ch2: [Chapter Name]
[Same structure]

### Ch3: ...
```

3. Show the plan. Ask: "Does this chapter breakdown look right? Revise as needed."

4. After user approves:
   - Save the chapter plan to `.opencode/SESSION.md` as the active chapter
   - Set Chapter 1 as "Active Chapter"
   - Mark all others as "Pending"

5. For any chapter that seems too large, propose splitting into sub-chapters:
   - Ch1a, Ch1b, etc.

6. After plan is finalized: "Chapter plan saved. Ready to start Ch1. Say 'proceed' to begin."

## Chapter Template
Each chapter must have:
- **Goal:** What the user can do after this chapter
- **DB schema changes:** Exact tables, columns, migrations
- **API endpoints:** Routes, request/response shapes
- **Test plan:** RSpec and/or Vitest test cases
- **Performance notes:** Indexes, caching, eager loading
