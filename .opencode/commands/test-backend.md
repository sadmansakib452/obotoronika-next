Run the complete backend test suite and report results.

Steps:
1. From the `backend/` directory, run:
   - `bundle exec rspec` — Full RSpec test suite
   - `bundle exec brakeman --no-pager -q` — Security scan
   - `bundle exec bundle-audit check --update` — Dependency vulnerability scan

2. Report results:
   - How many tests passed/failed
   - Any failures with the error message and file location
   - Any Brakeman security warnings (severity, file, line)
   - Any vulnerable dependencies found by bundle-audit

3. For any failures:
   - Analyze the root cause
   - Propose a fix
   - Do NOT apply the fix without user approval

4. If all pass, confirm: "All backend tests, security scans, and dependency audits pass."
