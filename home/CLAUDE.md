# Global instructions

How replies are formatted lives in the `Pro` output style. This file covers
how the work itself is done.

## Code

- Simplest thing that works. No abstraction for a single call site.
- Read a file before editing it. Follow the surrounding style over any
  general convention.
- Comments say *why*, never what. No `Added by`, `Updated by`, no dated notes.
- No docstrings or type hints on code the change does not touch.

## Commits

Angular format, enforced by the `commit-msg` hook:

```
<type>(<scope>): <subject>

<body: why, not what>
```

- Types: `build` `chore` `ci` `docs` `feat` `fix` `perf` `refactor` `test` `revert`.
- Subject: imperative, lowercase first letter, no trailing period, 72 chars max.
- Scope optional, lowercase (`[a-z0-9._/-]`).
- Breaking change: `!` after the scope **and** a `BREAKING CHANGE:` footer.
- One commit per logical change. Split by subject, not by file.
- Never `--no-verify`.

Never mention AI anywhere in commits, PRs, branch names or code: no
`Co-Authored-By: Claude`, no `Generated with Claude Code`, no
`Claude-Session:`. The work is mine.

PR descriptions state the user-visible change and the why. The diff already
lists the files.

## Documentation

- README answers what / why / getting started in under 5 commands. Everything
  else goes in `docs/`.
- Mermaid instead of a paragraph for architecture, flows, sequences and states.
- Tables for configuration and environment variables.
- Examples must be runnable, copy-paste safe.
- No filler sections ("Overview", "Key Takeaways", "Conclusion").
- Details: the `doc-writer` skill.

## Tone

Write like a person. No "It's important to note", no "not X, but Y" reflex,
no rule-of-three padding, no em dash inflation, no significance claims
("underscores", "represents a shift"). State the specific thing and stop.
Details: the `humanizer` skill.

## Tools

Installed and preferred where they fit: `ast-grep` for structural search and
rewrites, `difft` to read a diff, `kubeconform` to validate manifests offline.
`gcloud`, `glab`, `kubectl`, `helm`, `flux`, `argocd`, `tofu`, `terragrunt` and
`vault` are for reading; mutations go through IaC or CI.

## Delegation

Do the work inline by default, edits to `.tf`, manifests and code included. A
subagent earns its cost for parallel work, for long output that should stay
out of this conversation, or for a reviewer that has not seen the reasoning:

- `code-reviewer`: a finished change in Python or TypeScript, before the MR.
- `sre-auditor`: a reliability assessment.
- `incident-responder`: something broken in production.
- `presales-architect`: client deliverables.
- `iac-engineer`, `k8s-gitops-engineer`, `ai-platform-engineer`: a large,
  self-contained piece of work in their domain that can run while I continue.
