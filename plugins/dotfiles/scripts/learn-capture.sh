#!/usr/bin/env bash
#
# learn-capture.sh — SessionEnd hook: extract the learnings of the session that
# just ended into ~/.claude/learnings/inbox/, for `/learn review` to sort.
#
# The hook returns at once and the extraction runs detached, because SessionEnd
# does not wait for slow commands. The headless run has no tools: it only reads
# a digest of the transcript and prints, so it cannot touch memory or the repo.
# Nothing is promoted without going through `/learn review`.
#
# Usage: learn-capture.sh                       (hook, JSON on stdin)
#        learn-capture.sh --run <transcript> <cwd> <session_id>

set -uo pipefail

# The headless run is itself a session whose end fires this hook.
[ -n "${LEARN_CAPTURE:-}" ] && exit 0

INBOX="${HOME}/.claude/learnings/inbox"
MIN_PROMPTS=3

if [ "${1:-}" != "--run" ]; then
  input="$(cat)"
  transcript="$(jq -r '.transcript_path // empty' <<<"${input}")"
  cwd="$(jq -r '.cwd // empty' <<<"${input}")"
  sid="$(jq -r '.session_id // empty' <<<"${input}")"
  [ -f "${transcript}" ] || exit 0
  nohup "$0" --run "${transcript}" "${cwd}" "${sid}" >/dev/null 2>&1 &
  exit 0
fi

transcript="$2" cwd="$3" sid="$4"

# Short sessions rarely teach anything; skip them rather than pay for a run.
prompts="$(jq -s '[.[] | select(.type=="user" and (.message.content|type)=="string")] | length' "${transcript}")"
[ "${prompts}" -ge "${MIN_PROMPTS}" ] || exit 0

# What I typed, what Claude said, and the start of each tool result: enough to
# see corrections, failures and the Learnings sections subagents return.
digest="$(jq -r '
  select(.type=="user" or .type=="assistant") | select(.isSidechain != true)
  | .message.content as $c
  | if ($c|type)=="string" then "USER: " + $c
    else $c[]
      | if .type=="text" then "CLAUDE: " + .text
        elif .type=="tool_use" then "TOOL " + .name + ": " + (.input|tostring|.[0:300])
        elif .type=="tool_result" then "RESULT: " + ((.content|if type=="array" then map(.text? // "")|join(" ") else tostring end)|.[0:1500])
        else empty end
    end' "${transcript}" | tail -c 300000)"

read -r -d '' PROMPT <<'EOF'
You read the transcript digest of a finished Claude Code session and extract
what a future session should know. Keep a learning only if it would change
what a later session does: a correction from the user, an approach that failed
and why, an assumption that proved wrong, something that took several tries to
find, a line from a subagent's Learnings section. Skip what the code or the
git log already records, and anything only this conversation needed.

Print one line per learning, nothing else:
- [<destination>] <the learning, one specific sentence>

<destination> is one of: project (fact about this repo or client), agents-md
(the client's team should know it too), claude-md (how the user wants work
done everywhere), agent:<name>, skill:<name>, style (how replies are written),
settings (must never happen).

If there is nothing worth keeping, print exactly: NONE
EOF

mkdir -p "${INBOX}"
out="${INBOX}/$(date +%Y-%m-%d)-$(basename "${cwd}")-${sid:0:8}.md"

result="$(LEARN_CAPTURE=1 claude -p --model sonnet --tools "" --strict-mcp-config \
  --no-session-persistence --system-prompt "${PROMPT}" <<<"${digest}" 2>/dev/null)" || exit 0

case "${result}" in
  ""|NONE*) exit 0 ;;
esac

{
  printf -- '---\nproject: %s\nsession: %s\ntranscript: %s\n---\n\n' "${cwd}" "${sid}" "${transcript}"
  printf '%s\n' "${result}"
} >"${out}"
