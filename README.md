# dotfiles-claude

Versioned configuration for [Claude Code](https://claude.com/claude-code) — my personal
**agents**, **skills**, and a client-engagement **CLAUDE.md template**.

This repo is the single source of truth. On each machine, `~/.claude/agents` and
`~/.claude/skills` are **symlinks** into this repo, so editing files here (and committing)
is all that's needed to version-control my Claude Code setup. Nothing sensitive from
`~/.claude` (credentials, projects, history, settings) lives here or is ever committed.

## Contents

```
agents/                 # 7 subagent definitions (*.md)
skills/                 # skill folders, each with a SKILL.md
templates/
  CLAUDE.md.template    # engagement CLAUDE.md template (copy into client repos)
install.sh              # idempotent bootstrap: symlinks ~/.claude/{agents,skills} here
```

## Bootstrap on a new machine

Requires WSL2/Linux with the repo on the **Linux filesystem** (under `~`, never `/mnt/c`)
and an SSH `private` host alias for GitHub (see below).

```sh
git clone git@private:mjebalidev/dotfiles-claude.git ~/Private/dotfiles-claude
cd ~/Private/dotfiles-claude
./install.sh
```

`install.sh` is idempotent: if `~/.claude/agents` or `~/.claude/skills` already exist as
real directories, they are backed up to `*.bak.<n>` before the symlink is created. Running
it again when the correct symlinks are already in place is a no-op.

After bootstrapping, start a fresh Claude Code session and run `/agents` to confirm the
agents are picked up.

## SSH `private` host alias

The remote uses the `private` alias so the exact key/account is decided by `~/.ssh/config`.
Example block (ed25519):

```
Host private
  HostName github.com
  User git
  IdentityFile ~/.ssh/private
  IdentitiesOnly yes
```

## Editing

Edit files under this repo directly (the `~/.claude` symlinks point here), then commit:

```sh
cd ~/Private/dotfiles-claude
git add -A && git commit -m "Update agents/skills"
git push
```
