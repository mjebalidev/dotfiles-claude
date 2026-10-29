---
name: learn
description: Capture what this session taught into memory or into this config repo, or review the memories of every project and promote the ones that hold everywhere
disable-model-invocation: true
argument-hint: "[review]"
---

Two modes. No argument: capture this session. `review`: the weekly pass.

Every session that ends also leaves a file in `~/.claude/learnings/inbox/`
(the `SessionEnd` hook of the `dotfiles` plugin): one line per learning,
tagged with a destination, and the project path in the frontmatter. Those
lines are drafts from a model that saw a digest, not the session: check each
against the code or the destination before acting on it.

## Where a learning goes

First the layer, from the table in `home/CLAUDE.md` (*Where a piece of
knowledge goes*): generic, employer or client. A learning about one client
or about the employer never reaches this repo, however it is rephrased.

| The learning | Destination |
|---|---|
| A fact about this one repo: a build step, a code quirk | Project memory (the auto memory directory of this session) |
| A fact about a client that holds across its repos: an access path, an environment quirk, a decision | The `Learnings` section of `work-config/clients/<client>/CLAUDE.md`, which every session under that client loads |
| The same about the employer or its own platforms | The `Learnings` section of `work-config/employer/CLAUDE.md` |
| A fact the client's team should know too | The repo's `AGENTS.md`, proposed as a diff |
| How I want the work done, in every project | `home/CLAUDE.md` |
| A technique in a domain an agent covers | `agents/<name>.md` |
| A step missing from a procedure a skill covers | `skills/<name>/SKILL.md` |
| How replies are written | `output-styles/pro.md` |
| Something that must never happen | `home/settings.base.json` (`deny`/`ask`) or a hook, not prose |

Repo paths are relative to `~/Private/dotfiles-claude` (the target of the
`~/.claude/agents` symlink if the checkout moved); `work-config` paths to
`~/Projects/<employer>/work-config`.

## Capture (no argument)

1. Go through the conversation for: my corrections, approaches that failed
   and why, assumptions that turned out wrong, things that took several tries
   to find, and the **Learnings** sections that subagents returned.
2. Keep a learning only if it would change what a future session does, and it
   is not already in the code, the git log or an existing memory or rule.
   Read the destination before writing to it; update an entry rather than
   adding a near-duplicate.
3. Write project memories directly, in the format the memory instructions of
   this session give.
4. For the config repo, edit the file in place, one line or one bullet per
   learning, in the style of the surrounding text. Generalize first: no client
   names, hostnames, project IDs or people in the public repo; if the learning
   loses its point once generalized, it belongs in `work-config`. Do not
   commit; I run `/commit`.
5. Reply with one line per learning: destination, then the learning. Nothing
   to keep is a valid result; say so in one line.

## Review (`review`)

1. Read every `~/.claude/learnings/inbox/*.md`, every
   `~/.claude/projects/*/memory/*.md`, and `~/.claude/agent-memory/*/` if it
   exists.
2. Sort each inbox line and each memory into one of:
   - **Store**: an inbox line tagged `project`. Propose the project memory it
     becomes, in the memory directory of the project named in the file's
     frontmatter (`~/.claude/projects/<path with / turned into ->/memory/`).
   - **Route**: an inbox line tagged `client` or `employer`. Propose the line
     for the `Learnings` section of `work-config/clients/<client>/CLAUDE.md`
     or `work-config/employer/CLAUDE.md`; never the public repo.
   - **Promote**: an inbox line tagged anything else but `project`, a `feedback`
     memory that holds outside its project, or the same lesson in two
     projects or more. Propose the generalized line and its
     destination from the table above.
   - **Verify**: a `project` memory older than 30 days, or one that names a
     file, flag or resource. Check it still holds when it can be checked from
     here; otherwise ask.
   - **Drop**: an inbox line already covered, wrong, or of no use later.
   - **Keep**: a memory with nothing to do. Do not list these.
3. Show Store, Route, Promote, Verify and Drop as one table: source, proposal,
   destination. Wait for my answer.
4. Apply what I approve. A promoted memory is deleted from its project once
   the rule lives in the repo, and its line removed from that `MEMORY.md`.
   An inbox file is deleted once all its lines are handled.
   Do not commit.
