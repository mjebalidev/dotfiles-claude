#!/usr/bin/env bash
#
# install.sh — idempotently symlink ~/.claude/{agents,skills} to this repo.
#
# Safe to re-run. If ~/.claude/<name> is already the correct symlink, it is left
# untouched. If it is a real directory/file (or a wrong symlink), it is backed up
# to ~/.claude/<name>.bak.<n> before the correct symlink is created. Nothing is
# ever deleted.

set -euo pipefail

# Repo directory = location of this script, resolved to an absolute path.
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"

mkdir -p "${CLAUDE_DIR}"

link_one() {
  local name="$1"
  local target="${REPO_DIR}/${name}"
  local link="${CLAUDE_DIR}/${name}"

  if [ ! -d "${target}" ]; then
    echo "ERROR: expected source directory not found: ${target}" >&2
    return 1
  fi

  # Already the correct symlink -> nothing to do.
  if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${target}" ]; then
    echo "ok: ${link} -> ${target} (already linked)"
    return 0
  fi

  # Something else is there (real dir/file or a wrong symlink): back it up.
  if [ -e "${link}" ] || [ -L "${link}" ]; then
    local n=1
    while [ -e "${link}.bak.${n}" ] || [ -L "${link}.bak.${n}" ]; do
      n=$((n + 1))
    done
    local backup="${link}.bak.${n}"
    mv "${link}" "${backup}"
    echo "backed up: ${link} -> ${backup}"
  fi

  ln -s "${target}" "${link}"
  echo "linked: ${link} -> ${target}"
}

link_one agents
link_one skills

echo
echo "Done. Start a fresh Claude Code session and run /agents to confirm."
