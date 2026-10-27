#!/usr/bin/env bash
#
# format.sh — PostToolUse hook: format the file Claude just wrote or edited.
#
# Only formatters whose output is canonical run unconditionally (tofu/terraform
# fmt, terragrunt hcl fmt). Ruff and Prettier run only when the project already
# uses them, so a repo without them never gets a whole-file reformat.
# Never blocks: a formatter failure is the project's linter's business.

set -uo pipefail

file="$(jq -r '.tool_input.file_path // empty')"
[ -n "${file}" ] && [ -f "${file}" ] || exit 0

dir="$(dirname "${file}")"
root="$(git -C "${dir}" rev-parse --show-toplevel 2>/dev/null || echo "${dir}")"

# First ancestor of the file, up to the repo root, holding one of the given names.
find_up() {
  local d="${dir}" name
  while :; do
    for name in "$@"; do
      [ -e "${d}/${name}" ] && { printf '%s' "${d}"; return 0; }
    done
    [ "${d}" = "${root}" ] || [ "${d}" = "/" ] && return 1
    d="$(dirname "${d}")"
  done
}

case "${file}" in
  *.tf|*.tfvars|*.tftest.hcl)
    if command -v tofu >/dev/null; then tofu fmt "${file}"
    elif command -v terraform >/dev/null; then terraform fmt "${file}"
    fi
    ;;
  *.hcl)
    command -v terragrunt >/dev/null && terragrunt hcl fmt --file "${file}"
    ;;
  *.py)
    if command -v ruff >/dev/null &&
      { find_up ruff.toml .ruff.toml >/dev/null ||
        grep -qs '^\[tool\.ruff' "$(find_up pyproject.toml)/pyproject.toml"; }; then
      ruff format --quiet "${file}"
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css|*.scss|*.md|*.yaml|*.yml)
    if pkg="$(find_up .prettierrc .prettierrc.json .prettierrc.yaml .prettierrc.yml .prettierrc.js .prettierrc.cjs .prettierrc.mjs prettier.config.js prettier.config.cjs prettier.config.mjs)" &&
      [ -x "${pkg}/node_modules/.bin/prettier" ]; then
      "${pkg}/node_modules/.bin/prettier" --write --log-level silent "${file}"
    fi
    ;;
esac >/dev/null 2>&1

exit 0
