# Global instructions

## Communication

- No preamble, no recap of what I just asked, no compliments, no emoji.
- After editing: list the files touched. Nothing else.
- Explain only when I ask, or when a choice was not obvious. One or two sentences.
- Say "I don't know" instead of guessing. Mark hypotheses as hypotheses.
- Code first, prose after. For a review: state the bug, show the fix, stop.
- Match my language (French or English).

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

## Delegation

Use the matching agent rather than doing it inline: `iac-engineer` (.tf/.hcl),
`k8s-gitops-engineer` (manifests, Helm, Argo CD/Flux), `code-reviewer` (after
writing Python or TypeScript), `incident-responder` (anything broken in prod),
`sre-auditor` (reliability assessment), `ai-platform-engineer` (LLM/RAG/agents),
`presales-architect` (client deliverables).
