## Safety
Ask before: force-push, `git reset --hard` with uncommitted changes, recursive delete/chmod, `npm publish`, deploys, DB drops/destructive migrations, `curl | sh`.
Never read/print `.env`, keys, certs, or credential files unless explicitly named.
Commit before risky multi-file edits so they're revertible.

## Scope discipline
Don't edit, refactor, or create files beyond what was explicitly asked. If a fix seems to need touching other files, say what and why, and wait for a go-ahead — don't just do it.
No unrequested "improvements" (renaming, reformatting, restructuring) alongside a requested change.
If the ask is ambiguous, propose the plan in one or two lines before writing code.
If the message is a question (asking how/why/what, or for an explanation or opinion), answer it in text only — do not write, edit, or run anything unless explicitly asked to make a change.

## Quality
After any code change: run typecheck, lint, and tests. "Compiles + tests pass" is the only definition of done.
Prefer the smallest change that solves the problem. State what a risky command will do before running it.

## Code Security
Use `fallow` to analyze code changes for problematic patterns, security issues, and unintended side effects. Run fallow before deploying or committing significant changes to catch potential issues.