Run the complete storefront quality checks and tests.

Steps:
1. From `apps/storefront/`, run:
   - `npm run check` — Biome lint + format check
   - `npm run test` — Vitest test suite

2. Report results:
   - Any Biome lint violations (file, line, rule, message)
   - Any Biome format issues (files that need formatting)
   - How many Vitest tests passed/failed
   - Any test failures with error message and file location

3. For any issues:
   - If format issues only: suggest running `npm run format` to auto-fix
   - If lint violations: explain the rule, propose fix, ask approval
   - If test failures: analyze root cause, propose fix, ask approval

4. If all pass, confirm: "All storefront lint, format, and test checks pass."
