---
name: commit
description: Stage and commit the working tree as Angular commits, split by subject
disable-model-invocation: true
allowed-tools: Bash(git status:*), Bash(git diff:*), Bash(git add:*), Bash(git commit:*), Bash(git log:*), Bash(git apply:*), Bash(git restore:*)
---

Commit the current work.

## Gather

- `git status --short`
- `git diff` and `git diff --staged` — read them, do not skim
- `git log --oneline -10` — match the scopes and the phrasing already in use

## Split

One commit per logical change. A refactor and the feature built on it are two
commits. A file touched for two reasons belongs in two commits: stage hunks,
not files (`git apply --cached` with the hunk). Never bundle unrelated
changes to save a round trip.

If the working tree holds a single change, make a single commit. Do not invent
splits.

## Write

Format rules: `## Commits` in the global CLAUDE.md. On top of them:

- When a scope fits, take it from the paths touched and match the scopes in
  the log.
- Body: why the change was needed. Skip it when the subject already says
  everything. Never list the files.
- Last line: `Assisted-by: claude-code:<your model ID>` when this session
  wrote or shaped the change, unless the client's notes forbid it. A commit of
  work done without an agent gets none.

## Report

Reply with one line per commit, and nothing else:

```
<short hash> <type>(<scope>): <subject>
```

If the `commit-msg` hook rejects a message, fix the message and retry. Do not
bypass the hook.
