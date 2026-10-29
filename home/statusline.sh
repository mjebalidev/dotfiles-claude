#!/usr/bin/env bash
#
# statusline.sh — status line for Claude Code, Antigravity CLI and Copilot CLI,
# which all run a command with a JSON payload on stdin.
#
#   ☸ acme-prod-app │ ☁ acme │ ⇄ wg:dev │ ⎇ main !3 │ MR !42
#   Opus 5.5 · high ▰▰▱▱▱ 34% │ usage 5h 7% ↻14:30 │ ◆ qwen3-coder-30b │
#   ⚙ cpu ▕▂▂▏ 12%  ▦ ram ▕▆▆▏ 78% 18/24G  ◈ gpu ▕▃▃▏ 40%
#
# The cloud segment is the gcloud configuration (one per client, set by direnv)
# and the kube segment the context, red on production. Both are read straight
# from their config files: shelling out to gcloud costs a second per refresh.

set -uo pipefail

esc=$'\033'
reset="${esc}[0m" bold="${esc}[1m" dim="${esc}[2m"
red="${esc}[31m" green="${esc}[32m" yellow="${esc}[33m" blue="${esc}[34m"
magenta="${esc}[35m" cyan="${esc}[36m"
prod="${esc}[1;97;41m"
os="$(uname -s)"

# Every field in one jq call (one call costs ~6 ms, there used to be ten). The
# unit separator, unlike a tab, does not collapse empty fields when read.
# The same script serves Claude Code, Antigravity and Copilot CLI: fields that
# differ between them are read with fallbacks, and plan usage is normalised to
# "label:percent:reset-epoch" windows separated by ";".
#   Claude Code   rate_limits.five_hour / seven_day {used_percentage, resets_at}
#   Antigravity   quota.<bucket> {remaining_fraction, reset_in_seconds, disabled}
#   Copilot CLI   cost.total_premium_requests (a count; it exposes no quota)
us=$'\037'
IFS="${us}" read -r model_name fast effort ctx cwd pr pr_kind windows premium cache_warm cache_expires cache_requests < <(
  jq -r --arg us "${us}" '
    def window_name: if test("week") then "week" elif test("day|daily") then "day"
               elif test("5h|five|hour") then "5h" else . end;
    [
      .model.display_name, .fast_mode, (.effort.level // .model.effort),
      (.context_window.current_context_used_percentage // .context_window.used_percentage),
      (.workspace.current_dir // .cwd), .pr.number, .pr.kind,
      ( if .rate_limits then
          [ (.rate_limits.five_hour | select(. != null) | "5h:\(.used_percentage // ""):\(.resets_at // "")"),
            (.rate_limits.seven_day | select(. != null) | "week:\(.used_percentage // ""):\(.resets_at // "")") ]
        elif (.quota | type) == "object" then
          [ .quota | to_entries[] | select((.value.disabled // false) | not)
            | select(.value.remaining_fraction != null)
            | {l: (.key | window_name), p: ((1 - .value.remaining_fraction) * 100 | round),
               r: (if .value.reset_in_seconds then (now + .value.reset_in_seconds | floor) else "" end)} ]
          | sort_by({"5h": 0, "day": 1, "week": 2}[.l] // 3) | map("\(.l):\(.p):\(.r)")
        else [] end | join(";") ),
      .cost.total_premium_requests,
      .prompt_cache.warm, .prompt_cache.expires_at, .prompt_cache.requests
    ] | map(if . == null then "" else tostring end) | join($us)' 2>/dev/null
)

# A whole number from whatever came in ("69.5", "", "n/a"), or nothing.
int() {
  local v="${1%%.*}"
  case "${v}" in '' | *[!0-9]*) return 1 ;; esac
  printf '%s' "$((10#${v}))"
}

# Two lines by theme: where the agent works (cluster, cloud, VPN, git), then
# the session and the machine. The left of each line survives truncation.
kube=() cloud=() vpn=() git=() model=() usage_seg=() local_seg=() machine=()

# Groups can be hidden, without restarting the session, in
# ~/.config/statusline.conf:  STATUSLINE_HIDE="machine vpn"
# Groups: kube cloud vpn git model usage local machine. A hidden group runs no
# probe. STATUSLINE_SYSTEM=0 still hides the machine group.
STATUSLINE_HIDE="${STATUSLINE_HIDE:-}"
# shellcheck source=/dev/null
[ -r "${HOME}/.config/statusline.conf" ] && . "${HOME}/.config/statusline.conf"
[ "${STATUSLINE_SYSTEM:-1}" = "0" ] && STATUSLINE_HIDE+=" machine"
shown() { case " ${STATUSLINE_HIDE} " in *" $1 "*) return 1 ;; esac; }

# Production and test are recognised as whole words of a name, so "acme-prod",
# "prod_eu" and "gke_acme-prod-0_…" count, and "product" does not.
is_prod() { [[ "$1" =~ (^|[-_.])prod([-_.]|$) ]]; }
is_test() { [[ "$1" =~ (^|[-_.])(test|int)([-_.]|$) ]]; }

head=""
[ -n "${model_name}" ] && head="${bold}${model_name}${reset}"
[ "${fast}" = "true" ] && head+="${head:+ }${yellow}fast${reset}"
[ -n "${effort}" ] && head+="${head:+ ${dim}·${reset} }${effort}"
if pct="$(int "${ctx}")"; then
  if [ "${pct}" -ge 80 ]; then color="${red}"; elif [ "${pct}" -ge 50 ]; then color="${yellow}"; else color="${green}"; fi
  filled=$(((pct + 10) / 20)) bar=""
  for i in 1 2 3 4 5; do if [ "${i}" -le "${filled}" ]; then bar+="▰"; else bar+="▱"; fi; done
  head+="${head:+ }${color}${bar} ${pct}%${reset}"
fi
# Prompt cache: an idle session loses it, and the next message then re-reads
# the whole context at full price. Shown only when it matters: in the last
# five minutes before it expires, or once it has gone cold.
if requests="$(int "${cache_requests}")" && [ "${requests}" -gt 0 ]; then
  if [ "${cache_warm}" = "false" ]; then
    head+="${head:+ }${esc}[38;5;131mcache cold${reset}"
  elif expires="$(int "${cache_expires}")"; then
    left=$((expires - $(date +%s)))
    if [ "${left}" -le 300 ] && [ "${left}" -gt 0 ]; then
      if [ "${left}" -ge 60 ]; then left_txt="$((left / 60))m"; else left_txt="${left}s"; fi
      head+="${head:+ }${esc}[38;5;251mcache expires in ${left_txt}${reset}"
    fi
  fi
fi
[ -n "${head}" ] && model=("${head}")

# --no-optional-locks: a refresh must never take the index lock the agent's
# own git commands need. -uno: untracked files are the slow part in big repos.
# A detached HEAD (rebase, tag) shows its short hash instead of vanishing.
if shown git && git -C "${cwd:-.}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch="$(git -C "${cwd:-.}" symbolic-ref --short -q HEAD 2>/dev/null ||
    printf '@%s' "$(git -C "${cwd:-.}" rev-parse --short HEAD 2>/dev/null)")"
  seg="${magenta}⎇ ${branch}${reset}"
  dirty="$(git --no-optional-locks -C "${cwd:-.}" status --porcelain -uno 2>/dev/null | wc -l | tr -d ' ')"
  [ "${dirty}" != "0" ] && seg+=" ${yellow}!${dirty}${reset}"
  git+=("${seg}")
fi
if [ -n "${pr}" ]; then
  if [ "${pr_kind}" = "mr" ]; then git+=("${cyan}MR !${pr}${reset}"); else git+=("${cyan}PR #${pr}${reset}"); fi
fi

# Connected VPN tunnels, macOS only: every VPN app (WireGuard, Firezone, …)
# registers its tunnels with the network extension framework, which scutil
# lists without root. Nothing is shown when no tunnel is up.
if shown vpn && command -v scutil >/dev/null; then
  while IFS=$'\t' read -r kind name; do
    [ -n "${name}" ] || continue
    if is_prod "${name}"; then vpn+=("${prod} ⇄ ${kind}:${name} ${reset}"); else vpn+=("${cyan}⇄ ${kind}:${name}${reset}"); fi
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

# Bar gauges for machine load.
gauge() {
  local pct="$1" warn="$2" crit="$3" icon="$4" label="$5" suffix="${6:-}" c
  # A two-cell tank: the level fills from the bottom in the metric's colour,
  # the empty part stays a dark grey background, and thin side bars hug it
  # (right-eighth block before, left-eighth after) so it reads as a rectangle.
  # An array, not a substring: slicing multibyte glyphs breaks outside UTF-8 locales.
  local bars=(" " ▁ ▂ ▃ ▄ ▅ ▆ ▇ █) tank="${esc}[48;5;237m" edge="${esc}[38;5;244m" g
  [ "${pct}" -gt 100 ] && pct=100
  # The fill carries the colour; the text stays in greys and only turns a muted
  # red at the critical threshold, so the line stays calm until it matters.
  local t
  if [ "${pct}" -ge "${crit}" ]; then c="${red}" t="${esc}[38;5;131m"
  elif [ "${pct}" -ge "${warn}" ]; then c="${yellow}" t="${esc}[38;5;251m"
  else c="${green}" t="${esc}[38;5;245m"; fi
  g="${bars[$(((pct * 8 + 99) / 100))]}"
  printf '%s%s %s %s▕%s%s%s%s%s▏%s %s%%%s%s' "${t}" "${icon}" "${label}" "${edge}" "${tank}${c}" "${g}" "${g}" "${reset}" "${edge}" "${reset}${t}" "${pct}" "${suffix}" "${reset}"
}

# Plan usage, adaptive and in words: quiet when there is room, detailed near a
# limit. The first (shortest) window always shows with its reset time, which
# turns into a countdown from 70%; longer windows show from 50%, or when they
# are the only one. Works for any tool that passes windows (see the jq above).
#   usage 5h 7% ↻19:50
#   usage 5h 74% resets in 56m · week 52% ↻Tue 14:00
#   usage week 6% ↻Mon 07:50                   (Antigravity: one weekly bucket)
#   usage 12 premium requests                  (Copilot: a count, no quota)
# Greys, then a lighter grey from 70% and a muted red from 90%.
fmt_time() {
  if [ "${os}" = "Darwin" ]; then date -r "$1" "+$2" 2>/dev/null; else date -d "@$1" "+$2" 2>/dev/null; fi
}
countdown() {
  local left=$(($1 - $(date +%s)))
  [ "${left}" -lt 0 ] && left=0
  if [ "${left}" -ge 3600 ]; then printf '%dh%02d' $((left / 3600)) $((left % 3600 / 60)); else printf '%dm' $((left / 60)); fi
}
shade() {
  if [ "$1" -ge 90 ]; then printf '%s' "${esc}[38;5;131m"
  elif [ "$1" -ge 70 ]; then printf '%s' "${esc}[38;5;251m"
  else printf '%s' "${esc}[38;5;245m"; fi
}
grey="${esc}[38;5;245m" sep="${esc}[38;5;241m·${grey}" usage="" n=0 count=0
[ -n "${windows}" ] && count=$(($(tr -cd ';' <<<"${windows}" | wc -c) + 1))
IFS=';' read -r -a wins <<<"${windows}"
for w in ${wins[@]+"${wins[@]}"}; do
  n=$((n + 1))
  IFS=':' read -r wlabel wpct wreset <<<"${w}"
  wpct="$(int "${wpct}")" || continue
  wreset="$(int "${wreset}")" || wreset=""
  [ "${n}" -gt 1 ] && [ "${wpct}" -lt 50 ] && continue
  part="$(shade "${wpct}")${wlabel} ${wpct}%${grey}"
  if [ -n "${wreset}" ]; then
    if [ "${wpct}" -ge 70 ]; then part+=" resets in $(countdown "${wreset}")"
    elif [ $((wreset - $(date +%s))) -lt 86400 ]; then part+=" ↻$(fmt_time "${wreset}" %H:%M)"
    else part+=" ↻$(fmt_time "${wreset}" '%a %H:%M')"; fi
  fi
  usage+="${usage:+ ${sep} }${part}"
done
if [ -z "${usage}" ] && [ "${count}" -eq 0 ] && premium="$(int "${premium}")" && [ "${premium}" -gt 0 ]; then
  usage="${premium} premium request$([ "${premium}" -gt 1 ] && echo s)"
fi
[ -n "${usage}" ] && usage_seg=("${grey}usage ${usage}${reset}")

# Local models: LM Studio's server lists what is loaded; shown only while a
# model is. Every probe is cheap (sysctl, vm_stat, ps, ioreg): no top, no lms
# (which can launch the app).
lms_port="${LMSTUDIO_PORT:-1234}"
lms_models=""
shown local && lms_models="$(curl -s -m 0.3 "http://127.0.0.1:${lms_port}/api/v0/models" 2>/dev/null |
  jq -r '[.data[]? | select(.state == "loaded") | .id] | join(", ")' 2>/dev/null)"
[ -n "${lms_models}" ] && local_seg=("${magenta}◆ ${lms_models}${reset}")

# Machine load. Each metric gets an icon and a gauge in its own colour: green,
# yellow, red past its warn and crit thresholds. RAM warns earlier, since a
# model that no longer fits swaps. A probe that returns nothing usable is left
# out rather than shown as zero.
if shown machine; then
  cpu_label="cpu"
  if [ "${os}" = "Darwin" ]; then
    ncpu="$(sysctl -n hw.ncpu 2>/dev/null)"
    cpu="$(ps -A -o %cpu= 2>/dev/null | awk -v n="${ncpu:-1}" '{s += $1} END {printf "%.0f", s / n}')"
    mem_total="$(sysctl -n hw.memsize 2>/dev/null)"
    # Used = app (active) + wired + compressed, as Activity Monitor counts it.
    mem_used="$(vm_stat 2>/dev/null | awk -F: '
      /page size of/ {match($0, /[0-9]+/); size = substr($0, RSTART, RLENGTH)}
      /Pages active/ || /Pages wired down/ || /occupied by compressor/ {gsub(/[ .]/, "", $2); p += $2}
      END {printf "%.0f", p * size}')"
    gpu="$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null | grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2)"
  else
    # One sample of /proc/stat cannot give CPU %, and sampling twice costs a
    # sleep: show the load average per core, and call it load.
    cpu_label="load"
    ncpu="$(nproc 2>/dev/null)"
    cpu="$(awk -v n="${ncpu:-1}" '{printf "%.0f", $1 / n * 100}' /proc/loadavg 2>/dev/null)"
    mem_total="$(awk '/MemTotal/ {printf "%.0f", $2 * 1024}' /proc/meminfo 2>/dev/null)"
    mem_used="$(awk '/MemTotal/ {t = $2} /MemAvailable/ {a = $2} END {printf "%.0f", (t - a) * 1024}' /proc/meminfo 2>/dev/null)"
    gpu="$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1)"
  fi
  sys=""
  cpu="$(int "${cpu}")" && sys+="$(gauge "${cpu}" 60 85 ⚙ "${cpu_label}")"
  if mem_total="$(int "${mem_total}")" && mem_used="$(int "${mem_used}")" && [ "${mem_total}" -gt 0 ]; then
    sys+="${sys:+  }$(gauge "$((mem_used * 100 / mem_total))" 75 90 ▦ ram " $((mem_used / 1073741824))/$((mem_total / 1073741824))G")"
  fi
  gpu="$(int "${gpu}")" && sys+="${sys:+  }$(gauge "${gpu}" 60 85 ◈ gpu)"
  [ -n "${sys}" ] && machine=("${sys}")
fi

if shown cloud; then
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
    cloud+=("${blue}☁ ${conf}${reset}")
  elif [ -n "${project}" ]; then
    cloud+=("${blue}☁ ${project}${reset}")
  fi
fi

if shown kube; then
  kubeconfig="${KUBECONFIG:-${HOME}/.kube/config}"
  kubeconfig="${kubeconfig%%:*}"
  kctx="$(awk '/^current-context:/{print $2; exit}' "${kubeconfig}" 2>/dev/null)"
  [ "${kctx}" = '""' ] && kctx=""
  if [ -n "${kctx}" ]; then
    # Classify on the full name, before gke_<project>_<location>_<cluster> is
    # shortened to <cluster>: "prod" may only appear in the project.
    label="${kctx}"
    [[ "${kctx}" == gke_*_*_* ]] && label="${kctx##*_}"
    if is_prod "${kctx}"; then kube+=("${prod} ☸ ${label} ${reset}")
    elif is_test "${kctx}"; then kube+=("${yellow}☸ ${label}${reset}")
    else kube+=("${green}☸ ${label}${reset}"); fi
  elif [[ "${kubeconfig}" == */.kube/configs/*/config ]]; then
    # A client kubeconfig with no context picked yet.
    client="${kubeconfig%/config}"
    kube+=("${dim}☸ ${client##*/} · no context${reset}")
  fi
fi

join() {
  local out="" p
  for p in "$@"; do out+="${out:+ ${dim}│${reset} }${p}"; done
  printf '%s' "${out}"
}
# Characters on screen, whatever the caller's locale: in C, wc counts bytes.
visible() {
  local utf8="C.UTF-8"
  [ "${os}" = "Darwin" ] && utf8="en_US.UTF-8"
  sed $'s/\033\\[[0-9;]*m//g' <<<"$1" | LC_ALL="${utf8}" wc -m | tr -d ' '
}

# Keep only the groups that are shown, in display order. Explicit rather than
# clever: bash 3.2 (stock macOS) has no mapfile or namerefs.
first=() second=()
shown kube && first+=(${kube[@]+"${kube[@]}"})
shown cloud && first+=(${cloud[@]+"${cloud[@]}"})
shown vpn && first+=(${vpn[@]+"${vpn[@]}"})
shown git && first+=(${git[@]+"${git[@]}"})
shown model && second+=(${model[@]+"${model[@]}"})
shown usage && second+=(${usage_seg[@]+"${usage_seg[@]}"})
shown local && second+=(${local_seg[@]+"${local_seg[@]}"})
line1="$(join ${first[@]+"${first[@]}"})"
line2="$(join ${second[@]+"${second[@]}"} ${machine[@]+"${machine[@]}"})"
# The machine gauges move to a third line when the second would wrap. Claude
# Code sets COLUMNS for the command; 120 covers a manual run.
if [ "${#machine[@]}" -gt 0 ] && [ "${#second[@]}" -gt 0 ] && [ "$(visible "${line2}")" -gt "${COLUMNS:-120}" ]; then
  line2="$(join ${second[@]+"${second[@]}"})"$'\n'"${machine[0]}"
fi
nl=$'\n'
out="${line1}"
[ -n "${line2}" ] && out+="${out:+${nl}}${line2}"
printf '%s' "${out}"
