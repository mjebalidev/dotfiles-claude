---
description: Stage and commit the working tree as Angular commits, split by subject
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*)
---

Commit the current work.

## Gather

- `git status --short`
- `git diff` and `git diff --staged` — read them, do not skim
- `git log --oneline -10` — match the scopes and the phrasing already in use

## Split

One commit per logical change. A refactor and the feature built on it are two
commits. A file touched for two reasons belongs in two commits: stage hunks,
not files. Never bundle unrelated changes to save a round trip.

If the working tree holds a single change, make a single commit. Do not invent
splits.

## Write

```
<type>(<scope>): <subject>

<body>
```

- Types: `build` `chore` `ci` `docs` `feat` `fix` `perf` `refactor` `test` `revert`.
- Subject: imperative, lowercase first letter, no trailing period, 72 chars max.
- Scope: taken from the paths touched, lowercase, matching the scopes in the log.
- Body: why the change was needed. Skip it when the subject already says
  everything. Never list the files — the diff does that.
- Breaking change: `!` after the scope and a `BREAKING CHANGE:` footer.
- No AI attribution of any kind. No `--no-verify`.

## Report

Reply with one line per commit, and nothing else:

```
<short hash> <type>(<scope>): <subject>
```

If the `commit-msg` hook rejects a message, fix the message and retry. Do not
bypass the hook.
