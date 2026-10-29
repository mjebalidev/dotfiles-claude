---
name: learn
description: Capture what this session taught into project memory or into this config repo, or review project memories and promote the ones that hold everywhere
disable-model-invocation: true
argument-hint: "[review]"
---

Two modes. No argument: capture this session. `review`: the periodic pass.

A team configuration may ship its own `learn`, which then replaces this one
and adds routing to the team's shared repos.

## Where a learning goes

First decide who may read it. This repo is public: a fact about an employer
or a client never goes here, however it is rephrased; it goes to that
employer's or client's private repo, if there is one, or stays in project
memory.

| The learning | Destination |
|---|---|
| A fact about this one repo: a build step, a code quirk | Project memory (the auto memory directory of this session) |
| A fact about an employer or a client | Their private repo, or project memory |
| A fact the repo's whole team should know | The repo's `AGENTS.md`, proposed as a diff |
| How I want the work done, in every project | `home/CLAUDE.md` |
| A technique in a domain a subagent covers | `agents/<name>.md` |
| A step missing from a procedure a skill covers | `skills/<name>/SKILL.md` |
| How replies are written | `output-styles/pro.md` |
| Something that must never happen | A permission rule or a hook, not prose |

Repo paths are relative to this repo's checkout (the target of the
`~/.claude/skills/learn` link).

## Rules for every entry

- Keep a learning only if it would change what a future session does and an
  agent could not work it out from the code, the git log or an existing
  memory or rule. Standard conventions do not qualify.
- One line per learning; its date and origin belong in the commit, not the
  file.
- Budgets: `home/CLAUDE.md` 200 lines, a `SKILL.md` 500. A learning that
  would break one comes with a proposal to make room: prune an entry, or move
  a topic of ten lines or more into a skill and leave one line that names it.
- Generalize before writing to this repo: no client names, hostnames, project
  IDs or people. If the learning loses its point once generalized, it does
  not belong here.

## Capture (no argument)

1. Go through the conversation for: my corrections, approaches that failed
   and why, assumptions that turned out wrong, things that took several tries
   to find, and the **Learnings** sections that subagents returned.
2. Apply the rules above. Read the destination before writing to it; update
   an entry rather than adding a near-duplicate.
3. Write project memories directly, in the format the memory instructions of
   this session give. Edit config files in place, in the style of the
   surrounding text. Do not commit; I run `/commit`.
4. Reply with one line per learning: destination, then the learning. Nothing
   to keep is a valid result; say so in one line.

## Review (`review`)

1. Read every `~/.claude/projects/*/memory/*.md`, and
   `~/.claude/learnings/inbox/*.md` if something captured learnings there.
2. Sort each memory and inbox line into one of:
   - **Promote**: a `feedback` memory that holds outside its project, or the
     same lesson in two projects or more. Propose the generalized line and
     its destination from the table above.
   - **Verify**: a memory older than 30 days, or one that names a file, flag
     or resource. Check it still holds when it can be checked from here;
     otherwise ask.
   - **Drop**: already covered, wrong, or of no use later.
   - **Keep**: nothing to do. Do not list these.
3. Show Promote, Verify and Drop as one table: source, proposal, destination.
   Wait for my answer.
4. Apply what I approve. A promoted memory is deleted from its project once
   the rule lives in the repo, and its line removed from that `MEMORY.md`.
   Do not commit.
