# My Claude Code routine

What changes day to day with this config. One line per habit.

## Starting a session

| Before | Now |
|---|---|
| `claude` in the repo | `claude -w <name>` for any task that can run alongside another (one worktree per session) |
| Checking the gcloud project and kube context by hand | Read the status line: `☁ <gcloud configuration>` and `⎈ <context>` (or `⎈ <client> · no context`) are always shown |
| Nothing | `/effort low` to iterate fast, `/effort xhigh` for a hard bug, `ultrathink` for a single question |

## Clients, clusters and cloud accounts

One folder per client. The `.envrc` at its root selects that client's
kubeconfig, gcloud configuration and ADC. Outside it, gcloud uses the default
account and kubectl sees no client cluster.

| Before | Now |
|---|---|
| `kubectx`, which switches the context of every terminal | `cd` into the client folder, then `kx` (fzf) or `kx <context>`: the context holds for this terminal only, `kx -` drops it. No default context: a new terminal never lands on production |
| Guessing which cluster you are on | Prompt and Claude's status line: `☁ <client>` and `⎈ <context>`, red background on production, yellow on test/int. k9s frames production in red |
| One `~/.kube/config` with every cluster | `~/.kube/configs/<client>/config`, rebuilt by `kube-sync <client>` from `~/.config/kube/clusters.d/` (fragments from a private repo) |
| `gcloud container clusters get-credentials` | Add the cluster to the inventory (`dns_endpoint`, `internal_ip`, `prod`), then `kube-sync <client>` |
| `gcloud config set account` per client | Nothing: `CLOUDSDK_ACTIVE_CONFIG_NAME` follows the folder |
| Terraform with whatever ADC was logged in last | `GOOGLE_APPLICATION_CREDENTIALS` follows the folder (`adc-<client>.json`). ADC expire: `gcloud auth application-default login --account <account>`, then copy the file again |
| Remembering not to touch production | `*-prod-*` contexts open read-only in k9s |
| Explaining the client to Claude every session | A `CLAUDE.md` in the client folder, outside any code repo, loaded automatically |
| A new working folder | Create it under the right client folder: git identity (`includeIf`) and environment follow |

A client's or employer's context lives in a private repo per mission, cloned
into the mission folder and linked into place; edit the file in that repo,
never the link target. This repo stays public and generic.

## While working

| Before | Now |
|---|---|
| "Do it with the iac-engineer agent" | Let Claude work directly. Subagents are for parallel work, long output that should stay out of the conversation, or a fresh-eyes review |
| Reminding it to format | Nothing to do: `tofu fmt` and `terragrunt hcl fmt` run after every edit, `ruff`/`prettier` where the project uses them |
| Running `tofu validate` to see errors | Claude sees `terraform-ls`, `yaml-language-server` and `pyright` diagnostics right after each edit |
| Watching that it does not run an `apply` | With a team configuration installed, its permission rules make the common mutating commands (`kubectl apply/delete/exec`, `helm upgrade`, `tofu apply`, `gcloud … delete`, `glab mr merge/approve`, `vault write`…) ask first, auto mode included. An unusual form (`sh -c …`) can slip through: the sandbox (`/sandbox`) covers that |
| Correcting the same drift three times | `Esc` as soon as it drifts. After two failed corrections: `/clear` and a better prompt |
| A quick question that clutters the thread | `/btw <question>` |
| A long task that blocks the terminal | `/background`, then `claude agents` to follow it |

## Defining "done"

| Before | Now |
|---|---|
| "Is it done?" | Ask for evidence: the command run and its output (the `Pro` style already requires it) |
| A long task left alone | `/goal <checkable condition>`, for example `/goal tofu validate passes and the plan destroys nothing` |
| Nothing in the client repo | Copy `templates/settings.json.template` to `.claude/settings.json` and replace `REPLACE_WITH_CHECK` with the project's check: Claude cannot stop while it fails |

## Before a merge request

1. `/learn` if the session taught something worth keeping: sorted right away, with you.
2. `/commit`: Angular commits, split by subject. Only you can run it.
3. `/code-review` (or the `code-reviewer` agent): a review by eyes that did not see the reasoning.
4. `/security-review` if the change touches auth, secrets or IAM.

## A new client project

```sh
cp ~/Private/dotfiles-claude/templates/AGENTS.md.template AGENTS.md
```

Claude Code reads `AGENTS.md` directly as long as the repo has no
`CLAUDE.md`. If it has one, add the line `@AGENTS.md` to it.

Fill in `AGENTS.md` (60 lines at most, only what Claude cannot learn from the
code). Then, in a session, `/auto-mode-setup` so auto mode knows the client's
infrastructure.

## Deliverables (pre-sales, docs)

1. "Interview me until you could write the spec, then write SPEC.md".
2. A new session (`/clear`) to produce from `SPEC.md`.
3. Have it reviewed against `SPEC.md`, adding "skip style".
4. Write "be ambitious" when you want the full version.

## Maintaining the config (weekly)

| Command | For |
|---|---|
| `./install.sh --check` | Check that `~/.claude` matches the repo. If not: `./install.sh`. A list entry removed from the fragment must also be removed from `~/.claude/settings.json` by hand |
| `/insights` | See where sessions get stuck |
| `/learn review` | Sort the captured learnings and the project memories, promote what holds everywhere, re-check the oldest |
| `/skill-doctor` | Find skills that cost context without helping |
| `/usage` | See which agents cost the most |
| `/doctor prompt-audit` | Find stale or contradictory instructions |

A rule Claude misses twice goes into `home/CLAUDE.md` (`/learn` proposes it),
or into the team's rules when the whole team should follow it. A rule that
allows no exception goes into a permission rule or a hook, not into prose.
