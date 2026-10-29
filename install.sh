#!/usr/bin/env bash
#
# install.sh — deploy this repo into ~/.claude and ~/.gitconfig.
#
#   agents/ skills/ output-styles/   symlinked into ~/.claude/
#   home/CLAUDE.md                   symlinked to ~/.claude/CLAUDE.md
#   home/statusline.sh               symlinked to ~/.claude/statusline.sh
#   home/settings.base.json          merged into ~/.claude/settings.json
#   plugins/dotfiles                 installed from this repo as a marketplace
#   githooks/                        wired through git config --global core.hooksPath
#   bin/kube-sync                    symlinked into ~/.local/bin/
#   home/starship.toml               symlinked to ~/.config/starship.toml
#   home/k9s/skins/                  symlinked into the k9s skins directory
#   home/kube.zsh                    checked only: ~/.zshrc must source it (kx)
#
# Layered mode: when a team configuration (agent-config) generated
# ~/.claude/CLAUDE.md, only the personal layer is installed (CLAUDE.personal.md,
# output style, status line, prompt, skills the team does not ship, two
# settings keys); the team owns everything else.
#
# Idempotent. Nothing is deleted: anything in the way is moved to *.bak.<n>,
# and settings.json is copied to settings.json.bak.<n> before it is merged.
# Links are rebuilt from wherever the repo sits now, so re-running after a move
# (another machine, /home -> /Users) repairs them.
#
# Usage: ./install.sh [--no-git-hooks] [--check]
#   --check   report drift between this repo and ~/.claude, change nothing;
#             exits 1 when anything differs

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${HOME}/.claude"
FRAGMENT="${REPO_DIR}/home/settings.base.json"
SETTINGS="${CLAUDE_DIR}/settings.json"
MARKETPLACE="dotfiles-claude"
PLUGIN="dotfiles@${MARKETPLACE}"
WIRE_HOOKS=1
CHECK=0
DRIFT=0

for arg in "$@"; do
  case "${arg}" in
    --no-git-hooks) WIRE_HOOKS=0 ;;
    --check) CHECK=1 ;;
    *) echo "unknown option: ${arg}" >&2; exit 2 ;;
  esac
done

drift() {
  echo "DRIFT: $*"
  DRIFT=1
}

[ "${CHECK}" -eq 1 ] || mkdir -p "${CLAUDE_DIR}"

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
  local src="${REPO_DIR}/$1" link="${3:-${CLAUDE_DIR}}/${2:-$1}"

  if [ ! -e "${src}" ]; then
    echo "ERROR: missing source: ${src}" >&2
    return 1
  fi
  if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${src}" ]; then
    echo "ok: ${link}"
    return 0
  fi
  if [ "${CHECK}" -eq 1 ]; then
    drift "${link} does not point to ${src}"
    return 0
  fi
  if [ -e "${link}" ] || [ -L "${link}" ]; then
    backup "${link}"
  fi
  ln -s "${src}" "${link}"
  echo "linked: ${link} -> ${src}"
}

# A link this repo used to create and no longer ships. Removed only when it
# still points into a dotfiles-claude checkout, so a user's own file survives.
unlink_obsolete() {
  local link="${CLAUDE_DIR}/$1"
  [ -L "${link}" ] || return 0
  case "$(readlink "${link}")" in
    */dotfiles-claude/"$1") ;;
    *) return 0 ;;
  esac
  if [ "${CHECK}" -eq 1 ]; then
    drift "${link} is obsolete"
    return 0
  fi
  rm "${link}"
  echo "removed obsolete link: ${link}"
}

# Layered mode: a team configuration (agent-config) generated ~/.claude/CLAUDE.md
# and owns the shared rules, skills, agents, permissions, plugin and hooks.
# Only the personal layer goes on top, one link per item, so the two installs
# never write the same path or settings key.
install_personal_layer() {
  local d name
  echo "Team configuration found: installing the personal layer only."
  for d in output-styles skills; do
    if [ -L "${CLAUDE_DIR}/${d}" ]; then
      if [ "${CHECK}" -eq 1 ]; then drift "${CLAUDE_DIR}/${d} is a whole-directory link"; continue; fi
      rm "${CLAUDE_DIR}/${d}"
    fi
    [ "${CHECK}" -eq 1 ] || mkdir -p "${CLAUDE_DIR}/${d}"
  done
  link_one home/CLAUDE.personal.md CLAUDE.personal.md
  link_one home/statusline.sh statusline.sh
  for d in "${REPO_DIR}"/output-styles/*; do link_one "output-styles/${d##*/}"; done
  for d in "${REPO_DIR}"/skills/*/; do
    name="$(basename "${d}")"
    [ -f "${d}SKILL.md" ] || continue
    case "$(readlink "${CLAUDE_DIR}/skills/${name}" 2>/dev/null)" in
      */agent-config/*) echo "team: skills/${name}"; continue ;;
    esac
    link_one "skills/${name}"
  done
  [ "${CHECK}" -eq 1 ] || mkdir -p "${HOME}/.config"
  link_one home/starship.toml starship.toml "${HOME}/.config"

  # Settings: only the keys the team leaves to each person.
  local status=0
  python3 - "${SETTINGS}" "${FRAGMENT}" "$([ "${CHECK}" -eq 1 ] && echo check || echo write)" <<'PY' || status=$?
import json, sys

path, fragment_path, mode = sys.argv[1:4]
with open(path) as fh:
    settings = json.load(fh)
with open(fragment_path) as fh:
    fragment = json.load(fh)
mine = {k: fragment[k] for k in ("outputStyle", "statusLine") if k in fragment}
if all(settings.get(k) == v for k, v in mine.items()):
    sys.exit(0)
if mode == "check":
    sys.exit(3)
settings.update(mine)
with open(path, "w") as fh:
    json.dump(settings, fh, indent=2)
    fh.write("\n")
PY
  case "${status}" in
    0) echo "ok: ${SETTINGS}" ;;
    3) drift "${SETTINGS} lacks the personal keys" ;;
    *) echo "ERROR: could not update ${SETTINGS}" >&2; exit 1 ;;
  esac

  # A leftover of standalone mode the team layer now provides.
  if [ -L "${CLAUDE_DIR}/agents" ] && [[ "$(readlink "${CLAUDE_DIR}/agents")" == "${REPO_DIR}"/* ]]; then
    if [ "${CHECK}" -eq 1 ]; then drift "${CLAUDE_DIR}/agents still links here"; else rm "${CLAUDE_DIR}/agents"; fi
  fi

  if [ "${CHECK}" -eq 1 ]; then
    [ "${DRIFT}" -eq 0 ] && echo "In sync."
    exit "${DRIFT}"
  fi
  echo "Done."
  exit 0
}

if head -1 "${CLAUDE_DIR}/CLAUDE.md" 2>/dev/null | grep -q 'Generated by agent-config'; then
  install_personal_layer
fi

link_one agents
link_one skills
link_one output-styles
link_one home/CLAUDE.md CLAUDE.md
link_one home/statusline.sh statusline.sh
unlink_obsolete commands
[ "${CHECK}" -eq 1 ] || mkdir -p "${HOME}/.local/bin"
link_one bin/kube-sync kube-sync "${HOME}/.local/bin"
[ "${CHECK}" -eq 1 ] || mkdir -p "${HOME}/.config"
link_one home/starship.toml starship.toml "${HOME}/.config"

# k9s keeps its skins under a platform-specific directory; ask k9s for it.
if command -v k9s >/dev/null; then
  k9s_skins="$(k9s info 2>/dev/null | sed -n 's/.*Skins:[^/]*//p')"
  [ "${CHECK}" -eq 1 ] || mkdir -p "${k9s_skins}"
  link_one home/k9s/skins/prod.yaml prod.yaml "${k9s_skins}"
fi

# kx changes the calling shell's KUBECONFIG, so it is a function sourced from
# ~/.zshrc. The shell rc is the user's to edit: report, never append.
zsh_line="source \"${REPO_DIR}/home/kube.zsh\""
if grep -qxF "${zsh_line}" "${HOME}/.zshrc" 2>/dev/null; then
  echo "ok: ~/.zshrc sources home/kube.zsh"
else
  drift "~/.zshrc does not source home/kube.zsh; add: ${zsh_line}"
fi

# settings.json: merge the fragment, keep every other key untouched. Lists are
# unioned, fragment entries first, so permission rules saved from a prompt and
# auto mode entries written by /auto-mode-setup survive. Removing an entry from
# the fragment therefore does not remove it from settings.json: delete it there
# by hand. Scalars are fragment-owned and overwritten on every run.
if [ ! -f "${SETTINGS}" ]; then
  if [ "${CHECK}" -eq 1 ]; then drift "${SETTINGS} does not exist"; else echo '{}' > "${SETTINGS}"; fi
fi

# Exit 0 merged (or, with "check", in sync), 3 nothing to do (or drift).
merge_settings() {
  python3 - "$@" <<'PY'
import json, sys

settings_path, fragment_path, mode = sys.argv[1], sys.argv[2], sys.argv[3]
with open(settings_path) as fh:
    settings = json.load(fh)
with open(fragment_path) as fh:
    fragment = json.load(fh)


def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        elif isinstance(value, list) and isinstance(dst.get(key), list):
            dst[key] = value + [x for x in dst[key] if x not in value]
        else:
            dst[key] = value


before = json.dumps(settings, sort_keys=True)
merge(settings, fragment)
settings.pop("includeCoAuthoredBy", None)  # superseded by attribution
changed = json.dumps(settings, sort_keys=True) != before

if mode == "check":
    sys.exit(3 if changed else 0)
if not changed:
    sys.exit(3)

with open(settings_path, "w") as fh:
    json.dump(settings, fh, indent=2)
    fh.write("\n")
PY
}

if [ "${CHECK}" -eq 1 ]; then
  [ -f "${SETTINGS}" ] || exit 1
  status=0
  merge_settings "${SETTINGS}" "${FRAGMENT}" check || status=$?
  case "${status}" in
    0) echo "ok: ${SETTINGS}" ;;
    3) drift "${SETTINGS} is missing entries from home/settings.base.json" ;;
    *) echo "ERROR: cannot read ${SETTINGS}" >&2; exit 1 ;;
  esac
else
  scratch="$(mktemp)"
  cp "${SETTINGS}" "${scratch}"
  status=0
  merge_settings "${scratch}" "${FRAGMENT}" write || status=$?
  case "${status}" in
    0)
      settings_backup="$(backup_path "${SETTINGS}")"
      cp -p "${SETTINGS}" "${settings_backup}"
      # Write through the existing file so its mode and owner survive.
      cat "${scratch}" > "${SETTINGS}"
      rm -f "${scratch}"
      echo "backed up: ${SETTINGS} -> ${settings_backup}"
      echo "merged: ${SETTINGS} <- home/settings.base.json"
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
fi

# Plugin: this repo is its own marketplace. Re-registered when the recorded
# path is not this checkout.
if command -v claude >/dev/null; then
  registered="$(claude plugin marketplace list --json |
    python3 -c 'import json,sys; m=[x for x in json.load(sys.stdin) if x["name"]==sys.argv[1]]; print(m[0].get("path","") if m else "-")' "${MARKETPLACE}")"
  installed="$(claude plugin list --json |
    python3 -c 'import json,sys; print(any(p.get("id")==sys.argv[1] for p in json.load(sys.stdin)))' "${PLUGIN}")"

  if [ "${registered}" = "${REPO_DIR}" ] && [ "${installed}" = "True" ]; then
    echo "ok: plugin ${PLUGIN}"
  elif [ "${CHECK}" -eq 1 ]; then
    drift "plugin ${PLUGIN} is not installed from ${REPO_DIR}"
  else
    [ "${registered}" = "-" ] || claude plugin marketplace remove "${MARKETPLACE}"
    claude plugin marketplace add "${REPO_DIR}"
    claude plugin install "${PLUGIN}"
  fi

  # Every other plugin the fragment enables, from marketplaces already known.
  missing="$(claude plugin list --json | python3 -c '
import json, sys
installed = {p["id"] for p in json.load(sys.stdin)}
with open(sys.argv[1]) as fh:
    wanted = json.load(fh).get("enabledPlugins", {})
print(" ".join(k for k, on in wanted.items() if on and k not in installed and k != sys.argv[2]))
' "${FRAGMENT}" "${PLUGIN}")"
  for p in ${missing}; do
    if [ "${CHECK}" -eq 1 ]; then
      drift "plugin ${p} is enabled but not installed"
    else
      claude plugin install "${p}"
    fi
  done
else
  echo "WARNING: claude not on PATH; plugin ${PLUGIN} not checked." >&2
fi

# Git hooks.
if [ "${WIRE_HOOKS}" -eq 1 ]; then
  current="$(git config --global core.hooksPath || true)"
  if [ "${current}" = "${REPO_DIR}/githooks" ]; then
    echo "ok: core.hooksPath"
  elif [ "${CHECK}" -eq 1 ]; then
    drift "core.hooksPath is '${current}', expected ${REPO_DIR}/githooks"
  elif [ -z "${current}" ]; then
    chmod +x "${REPO_DIR}"/githooks/*
    git config --global core.hooksPath "${REPO_DIR}/githooks"
    echo "set: core.hooksPath -> ${REPO_DIR}/githooks"
  else
    echo "WARNING: core.hooksPath is already ${current}; left as is." >&2
  fi
fi

if [ "${CHECK}" -eq 1 ]; then
  [ "${DRIFT}" -eq 0 ] && echo "In sync."
  exit "${DRIFT}"
fi

echo
echo "Done. Start a fresh session; /agents and /commit should be available."
