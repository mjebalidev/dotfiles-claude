#!/usr/bin/env bash
#
# statusline.sh — Claude Code status line.
#
#   Opus 5.5 · high ▰▰▱▱▱ 34% │ ⎇ main !3 │ MR !42 │ ⇄ wg:dev │ ☁ acme │ ⎈ acme-prod-app
#
# The cloud segment is the gcloud configuration (one per client, set by direnv)
# and the kube segment the context, red on production. Both are read straight
# from their config files: shelling out to gcloud costs a second per refresh.

set -uo pipefail

in="$(cat)"
j() { jq -r "$1 // empty" <<<"${in}"; }

esc=$'\033'
reset="${esc}[0m" bold="${esc}[1m" dim="${esc}[2m"
red="${esc}[31m" green="${esc}[32m" yellow="${esc}[33m" blue="${esc}[34m"
magenta="${esc}[35m" cyan="${esc}[36m"
prod="${esc}[1;97;41m"

parts=()

head="${bold}$(j .model.display_name)${reset}"
[ "$(j .fast_mode)" = "true" ] && head+=" ${yellow}fast${reset}"
effort="$(j .effort.level)"
[ -n "${effort}" ] && head+=" ${dim}·${reset} ${effort}"
ctx="$(j .context_window.used_percentage)"
if [ -n "${ctx}" ]; then
  pct="${ctx%.*}"
  if [ "${pct}" -ge 80 ]; then color="${red}"; elif [ "${pct}" -ge 50 ]; then color="${yellow}"; else color="${green}"; fi
  filled=$(((pct + 10) / 20)) bar=""
  for i in 1 2 3 4 5; do if [ "${i}" -le "${filled}" ]; then bar+="▰"; else bar+="▱"; fi; done
  head+=" ${color}${bar} ${pct}%${reset}"
fi
parts+=("${head}")

cwd="$(j .workspace.current_dir)"
if branch="$(git -C "${cwd:-.}" symbolic-ref --short -q HEAD 2>/dev/null)"; then
  seg="${magenta}⎇ ${branch}${reset}"
  dirty="$(git -C "${cwd:-.}" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
  [ "${dirty}" != "0" ] && seg+=" ${yellow}!${dirty}${reset}"
  parts+=("${seg}")
fi

pr="$(j .pr.number)"
if [ -n "${pr}" ]; then
  if [ "$(j .pr.kind)" = "mr" ]; then parts+=("${cyan}MR !${pr}${reset}"); else parts+=("${cyan}PR #${pr}${reset}"); fi
fi

# Connected VPN tunnels, macOS only: every VPN app (WireGuard, Firezone, …)
# registers its tunnels with the network extension framework, which scutil
# lists without root. Nothing is shown when no tunnel is up.
if command -v scutil >/dev/null; then
  while IFS=$'\t' read -r kind name; do
    [ -n "${name}" ] || continue
    case "${name}" in
      *prod*) parts+=("${prod} ⇄ ${kind}:${name} ${reset}") ;;
      *) parts+=("${cyan}⇄ ${kind}:${name}${reset}") ;;
    esac
  done < <(scutil --nc list 2>/dev/null | awk -F'"' '
    /\((Connected|Connecting)\)/ {
      kind = "vpn"
      if ($0 ~ /com\.wireguard\./) kind = "wg"
      if ($0 ~ /firezone/) kind = "fz"
      name = $2
      if ($0 ~ /\(Connecting\)/) name = name "…"
      print kind "\t" name
    }')
fi

gcloud_dir="${CLOUDSDK_CONFIG:-${HOME}/.config/gcloud}"
conf="${CLOUDSDK_ACTIVE_CONFIG_NAME:-$(cat "${gcloud_dir}/active_config" 2>/dev/null)}"
conf="${conf:-default}"
project="${CLOUDSDK_CORE_PROJECT:-}"
if [ -z "${project}" ]; then
  project="$(awk -F' *= *' '/^\[/{core=($0=="[core]")} core && $1=="project"{print $2; exit}' \
    "${gcloud_dir}/configurations/config_${conf}" 2>/dev/null)"
fi
# The default configuration says nothing about the client: show its project only.
if [ "${conf}" != "default" ]; then
  parts+=("${blue}☁ ${conf}${reset}")
elif [ -n "${project}" ]; then
  parts+=("${blue}☁ ${project}${reset}")
fi

kubeconfig="${KUBECONFIG:-${HOME}/.kube/config}"
kubeconfig="${kubeconfig%%:*}"
kctx="$(awk '/^current-context:/{print $2; exit}' "${kubeconfig}" 2>/dev/null)"
[ "${kctx}" = '""' ] && kctx=""
# gke_<project>_<location>_<cluster> -> <cluster>
[[ "${kctx}" == gke_*_*_* ]] && kctx="${kctx##*_}"
if [ -n "${kctx}" ]; then
  case "${kctx}" in
    *-prod-*) parts+=("${prod} ⎈ ${kctx} ${reset}") ;;
    *-test-* | *-int-*) parts+=("${yellow}⎈ ${kctx}${reset}") ;;
    *) parts+=("${green}⎈ ${kctx}${reset}") ;;
  esac
elif [[ "${kubeconfig}" == */.kube/configs/*/config ]]; then
  # A client kubeconfig with no context picked yet.
  client="${kubeconfig%/config}"
  parts+=("${dim}⎈ ${client##*/} · no context${reset}")
fi

out=""
for p in "${parts[@]}"; do out+="${out:+ ${dim}│${reset} }${p}"; done
printf '%s' "${out}"
