#!/usr/bin/env bash
#
# statusline.sh — Claude Code status line.
#
#   Opus 5.5 · high ▰▰▱▱▱ 34% │ ⎇ main !3 │ MR !42 │ ⇄ wg:dev │ ◆ qwen3-coder-30b │
#   ⚙ cpu 12% · ram 18/24G · gpu 40% │ ☁ acme │ ⎈ acme-prod-app
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

# Local models: LM Studio's server lists what is loaded. Shown only while a
# model is loaded; the machine segment comes with it, or on demand with
# STATUSLINE_SYSTEM=1 or the file ~/.claude/statusline-system (toggled
# without restarting the session). Every probe is cheap (sysctl, vm_stat, ps, ioreg): no
# top, no lms (which can launch the app).
lms_port="${LMSTUDIO_PORT:-1234}"
lms_models="$(curl -s -m 0.3 "http://127.0.0.1:${lms_port}/api/v0/models" 2>/dev/null |
  jq -r '[.data[]? | select(.state == "loaded") | .id] | join(", ")' 2>/dev/null)"
[ -n "${lms_models}" ] && parts+=("${magenta}◆ ${lms_models}${reset}")

if [ -n "${lms_models}" ] || [ "${STATUSLINE_SYSTEM:-0}" = "1" ] || [ -e "${HOME}/.claude/statusline-system" ]; then
  if [ "$(uname -s)" = "Darwin" ]; then
    ncpu="$(sysctl -n hw.ncpu)"
    cpu="$(ps -A -o %cpu= | awk -v n="${ncpu}" '{s += $1} END {printf "%.0f", s / n}')"
    mem_total="$(sysctl -n hw.memsize)"
    # Used = app (active) + wired + compressed, as Activity Monitor counts it.
    mem_used="$(vm_stat | awk -F: '
      /page size of/ {match($0, /[0-9]+/); size = substr($0, RSTART, RLENGTH)}
      /Pages active/ || /Pages wired down/ || /occupied by compressor/ {gsub(/[ .]/, "", $2); p += $2}
      END {printf "%.0f", p * size}')"
    gpu="$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2)"
  else
    ncpu="$(nproc)"
    cpu="$(awk -v n="${ncpu}" '{printf "%.0f", $1 / n * 100}' /proc/loadavg)"
    mem_total="$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo)"
    mem_used="$(awk '/MemTotal/ {t = $2} /MemAvailable/ {a = $2} END {print (t - a) * 1024}' /proc/meminfo)"
    gpu="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)"
  fi
  mem_pct=$((mem_used * 100 / mem_total))
  if [ "${mem_pct}" -ge 90 ]; then color="${red}"; elif [ "${mem_pct}" -ge 75 ]; then color="${yellow}"; else color="${dim}"; fi
  sys="cpu ${cpu}% · ram $((mem_used / 1073741824))/$((mem_total / 1073741824))G"
  [ -n "${gpu}" ] && sys+=" · gpu ${gpu}%"
  parts+=("${color}⚙ ${sys}${reset}")
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
