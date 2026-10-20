# Sentinel Test Skill — Tests & Verification

- **Last updated:** 2026-10-20
- **Purpose:** The only approved way to test and verify AptReceipt.

## When to use

After every code, resource or project change, before reporting a task as done or committing.

## Steps

1. Run the full unit test suite:

   ```bash
   ./run_all_tests_mac.command
   ```

   It builds with `CODE_SIGNING_ALLOWED=NO` into `.deriveddata` and runs `aptreceiptTests` (late fee, drafts, settings characterization, toolbar tabs, WhatsApp messages, receipt periods, formatting and the trilingual parity tests).

2. For UI changes, also check the real running window (build the app and open it); offscreen renders are not enough.

## Rules

- Never report completion with a failing test; fix it or revert.
- Three consecutive failures on the same problem: stop and ask the user.
- Tests use the in-memory `InMemoryDefaults` and never the real `UserDefaults`; they must not leave files in `~/Library/Preferences`.
- Temporary screenshot or diagnostic tests are appended only for the run and removed right after; confirm the receipt archive checksum is unchanged.
- **Never** run the app with `--generate-screenshots` against real data (it replaces the receipt archive). Use an unsigned build in a scratch directory.
- When adding a guard test, prove it: add a deliberate violation, see the test fail, then remove the violation.
