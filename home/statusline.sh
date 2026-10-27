#!/usr/bin/env bash
#
# statusline.sh — Claude Code status line.
#
#   Opus 5.5 · high · ctx 12% │ main !3 │ MR !42 │ gcp:my-project │ k8s:prod-cluster
#
# Reads the active gcloud project and kube context straight from their config
# files: shelling out to gcloud costs a second on every refresh.

set -uo pipefail

in="$(cat)"
j() { jq -r "$1 // empty" <<<"${in}"; }

parts=()

head="$(j .model.display_name)"
effort="$(j .effort.level)"
ctx="$(j .context_window.used_percentage)"
[ "$(j .fast_mode)" = "true" ] && head+=" fast"
[ -n "${effort}" ] && head+=" · ${effort}"
[ -n "${ctx}" ] && head+=" · ctx ${ctx%.*}%"
parts+=("${head}")

cwd="$(j .workspace.current_dir)"
if branch="$(git -C "${cwd:-.}" symbolic-ref --short -q HEAD 2>/dev/null)"; then
  dirty="$(git -C "${cwd:-.}" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  [ "${dirty}" != "0" ] && branch+=" !${dirty}"
  parts+=("${branch}")
fi

pr="$(j .pr.number)"
if [ -n "${pr}" ]; then
  if [ "$(j .pr.kind)" = "mr" ]; then parts+=("MR !${pr}"); else parts+=("PR #${pr}"); fi
fi

gcloud_dir="${CLOUDSDK_CONFIG:-${HOME}/.config/gcloud}"
project="${CLOUDSDK_CORE_PROJECT:-}"
if [ -z "${project}" ]; then
  conf="${CLOUDSDK_ACTIVE_CONFIG_NAME:-$(cat "${gcloud_dir}/active_config" 2>/dev/null)}"
  project="$(awk -F' *= *' '/^\[/{core=($0=="[core]")} core && $1=="project"{print $2; exit}' \
    "${gcloud_dir}/configurations/config_${conf:-default}" 2>/dev/null)"
fi
[ -n "${project}" ] && parts+=("gcp:${project}")

kubeconfig="${KUBECONFIG:-${HOME}/.kube/config}"
kctx="$(awk '/^current-context:/{print $2; exit}' "${kubeconfig%%:*}" 2>/dev/null)"
# gke_<project>_<location>_<cluster> -> <cluster>
[[ "${kctx}" == gke_*_*_* ]] && kctx="${kctx##*_}"
[ -n "${kctx}" ] && parts+=("k8s:${kctx}")

out=""
for p in "${parts[@]}"; do out+="${out:+ │ }${p}"; done
printf '%s' "${out}"
