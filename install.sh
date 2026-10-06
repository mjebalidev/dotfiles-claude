#!/usr/bin/env bash
#
# install.sh — deploy this repo into ~/.claude and ~/.gitconfig.
#
#   agents/ skills/ commands/   symlinked into ~/.claude/
#   home/CLAUDE.md              symlinked to ~/.claude/CLAUDE.md
#   home/settings.attribution.json  merged into ~/.claude/settings.json
#   githooks/                   wired through git config --global core.hooksPath
#
# Idempotent. Nothing is deleted: anything in the way is moved to *.bak.<n>,
# and settings.json is copied to settings.json.bak.<n> before it is merged.
#
# Usage: ./install.sh [--no-git-hooks]

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
WIRE_HOOKS=1

for arg in "$@"; do
  case "${arg}" in
    --no-git-hooks) WIRE_HOOKS=0 ;;
    *) echo "unknown option: ${arg}" >&2; exit 2 ;;
  esac
done

mkdir -p "${CLAUDE_DIR}"

# Next free ${path}.bak.<n>.
backup_path() {
  local path="$1" n=1
  while [ -e "${path}.bak.${n}" ] || [ -L "${path}.bak.${n}" ]; do n=$((n + 1)); done
  printf '%s.bak.%s' "${path}" "${n}"
}

backup() {
  local path="$1" dest
  dest="$(backup_path "${path}")"
  mv "${path}" "${dest}"
  echo "backed up: ${path} -> ${dest}"
}

link_one() {
  local src="${REPO_DIR}/$1" link="${CLAUDE_DIR}/${2:-$1}"

  if [ ! -e "${src}" ]; then
    echo "ERROR: missing source: ${src}" >&2
    return 1
  fi
  if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${src}" ]; then
    echo "ok: ${link}"
    return 0
  fi
  if [ -e "${link}" ] || [ -L "${link}" ]; then
    backup "${link}"
  fi
  ln -s "${src}" "${link}"
  echo "linked: ${link} -> ${src}"
}

link_one agents
link_one skills
link_one commands
link_one home/CLAUDE.md CLAUDE.md

# settings.json: merge the fragment, keep every other key untouched.
SETTINGS="${CLAUDE_DIR}/settings.json"
FRAGMENT="${REPO_DIR}/home/settings.attribution.json"
[ -f "${SETTINGS}" ] || echo '{}' > "${SETTINGS}"

# Exit 0 merged, 3 nothing to do, anything else is a failure.
merge_settings() {
  python3 - "$1" "$2" <<'PY'
import json, sys

settings_path, fragment_path = sys.argv[1], sys.argv[2]
with open(settings_path) as fh:
    settings = json.load(fh)
with open(fragment_path) as fh:
    fragment = json.load(fh)


def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = value


before = json.dumps(settings, sort_keys=True)
merge(settings, fragment)
settings.pop("includeCoAuthoredBy", None)  # superseded by attribution

if json.dumps(settings, sort_keys=True) == before:
    sys.exit(3)

with open(settings_path, "w") as fh:
    json.dump(settings, fh, indent=2)
    fh.write("\n")
PY
}

scratch="$(mktemp)"
cp "${SETTINGS}" "${scratch}"
status=0
merge_settings "${scratch}" "${FRAGMENT}" || status=$?
case "${status}" in
  0)
    settings_backup="$(backup_path "${SETTINGS}")"
    cp -p "${SETTINGS}" "${settings_backup}"
    # Write through the existing file so its mode and owner survive.
    cat "${scratch}" > "${SETTINGS}"
    rm -f "${scratch}"
    echo "backed up: ${SETTINGS} -> ${settings_backup}"
    echo "merged: ${SETTINGS} <- home/settings.attribution.json"
    ;;
  3)
    rm -f "${scratch}"
    echo "ok: ${SETTINGS}"
    ;;
  *)
    rm -f "${scratch}"
    echo "ERROR: settings merge failed, ${SETTINGS} left untouched" >&2
    exit 1
    ;;
esac

# Git hooks.
if [ "${WIRE_HOOKS}" -eq 1 ]; then
  chmod +x "${REPO_DIR}"/githooks/*
  current="$(git config --global core.hooksPath || true)"
  if [ -z "${current}" ]; then
    git config --global core.hooksPath "${REPO_DIR}/githooks"
    echo "set: core.hooksPath -> ${REPO_DIR}/githooks"
  elif [ "${current}" = "${REPO_DIR}/githooks" ]; then
    echo "ok: core.hooksPath"
  else
    echo "WARNING: core.hooksPath is already ${current}; left as is." >&2
  fi
  echo "note: repos that set core.hooksPath themselves (Husky) bypass this hook."
fi

echo
echo "Done. Start a fresh session; /agents and /commit should be available."
