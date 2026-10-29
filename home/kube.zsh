# kube.zsh — pick a kube context for this shell only, inside the client that
# direnv selected. Sourced from ~/.zshrc.
#
#   kx            choose a context with fzf
#   kx <context>  choose it by name
#   kx -          back to the client kubeconfig, no context
#
# The chosen context is copied into a private temp kubeconfig, so other
# terminals and the client file keep no current-context. Each copy sits in its
# own directory because gke-gcloud-auth-plugin caches its token next to it.

kx() {
  local base="${KUBECONFIG:-}"
  # Already switched: go back to the client file recorded next to the copy.
  [[ "${base}" == */kx.*/config && -f "${base:h}/base" ]] && base="$(<"${base:h}/base")"
  if [[ -z "${base}" ]]; then
    print -u2 "kx: no KUBECONFIG here; cd into a client folder first"
    return 1
  fi
  if [[ "${1:-}" == "-" ]]; then
    export KUBECONFIG="${base}"
    return
  fi

  local ctx="${1:-}"
  [[ -n "${ctx}" ]] || ctx="$(kubectl --kubeconfig "${base}" config get-contexts -o name |
    fzf --height 40% --reverse --prompt 'context> ')"
  [[ -n "${ctx}" ]] || return 1

  local dir
  dir="$(mktemp -d "${TMPDIR:-/tmp}/kx.XXXXXX")" || return 1
  kubectl --kubeconfig "${base}" config view --flatten --minify --context "${ctx}" > "${dir}/config" || return 1
  chmod 600 "${dir}/config"
  print -r -- "${base}" > "${dir}/base"
  export KUBECONFIG="${dir}/config"
  [[ "${ctx}" == *-prod-* ]] && print -P "%F{red}%Bproduction%b%f: ${ctx}"
}

_kx() {
  local base="${KUBECONFIG:-}"
  [[ "${base}" == */kx.*/config && -f "${base:h}/base" ]] && base="$(<"${base:h}/base")"
  [[ -n "${base}" ]] || return
  compadd -- - $(kubectl --kubeconfig "${base}" config get-contexts -o name 2>/dev/null)
}
(( $+functions[compdef] )) && compdef _kx kx
