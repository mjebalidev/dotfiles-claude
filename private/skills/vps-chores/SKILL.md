---
name: vps-chores
description: Routine upkeep of my personal Coolify VPS — check everything it runs, then update the OS packages, Docker, the Coolify-managed infra (Traefik, Sentinel, monitoring) and the dependencies of every deployed app. Use when I ask for the VPS chores, "fais les corvées du VPS", a VPS check-up, or to update the VPS or the apps on it.
argument-hint: "[ssh-host]"
---

Upkeep of a single Ubuntu VPS that runs Docker and Coolify, with apps built
from GitHub repos. Personal projects only: this skill is installed under
`~/Private/.claude/skills/` and is not meant for client work.

The SSH host alias is the argument, `atelier` by default. The deploy user has
passwordless `sudo`. `gh` is logged in as the repos' owner.

Four phases. The first two only read; nothing changes on the host or in a
repo before I approve the plan from phase 3.

## Phase 1 — Inventory (read-only)

If the session folder holds notes about the VPS (a plan, a security TODO),
read them first: they record decisions not to revisit and open items.

Run these over `ssh <host>`; use `bash -c '…'` for loops, since the local
shell is zsh and does not word-split `$var`.

| What | How |
|---|---|
| OS, kernel, uptime, disk, RAM | `cat /etc/os-release`, `uname -r`, `uptime`, `df -h /`, `free -h` |
| Pending packages | `apt list --upgradable`; count them, single out `-security` and the kernel |
| Reboot already pending | `ls /var/run/reboot-required*` |
| What unattended-upgrades covers | `/etc/apt/apt.conf.d/50unattended-upgrades` (usually `-security` only: `-updates` and the Docker repo pile up) |
| Containers | `docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}'`; anything not `Up` or `unhealthy` goes to the top of the report |
| Container → app → repo | `docker exec coolify-db psql -U coolify -d coolify -tAc "select uuid,name,git_repository,git_branch,fqdn from applications"`; the container name starts with the app `uuid` |
| Host services and timers | `systemctl list-units --type=service --state=running`, `systemctl list-timers` |
| Coolify auto-update | `select is_auto_update_enabled from instance_settings` |
| Auto-deploy actually fires | last rows of `application_deployment_queues` against the repos' last push; if they lag, read the GitHub App's webhook URL and recent deliveries (below) |
| Disk held by images | `docker system df` |

Versions to compare with the latest release (`gh api repos/<r>/releases/latest --jq .tag_name`):

| Component | Running version | Upstream |
|---|---|---|
| Coolify, Sentinel | image tag | `coollabsio/coolify`, `coollabsio/sentinel` |
| Traefik (`coolify-proxy`) | `docker exec coolify-proxy traefik version` | `traefik/traefik` |
| Docker, containerd, compose | from `apt list --upgradable` | — |
| Host tools (Trivy, monitoring agents) | `<tool> --version` | their repo |
| Images tagged `latest` | image creation date | pin them to a version instead |

Application dependencies, for each repo from the Coolify table:

- **What runs on the VPS**: read the repo's Dockerfile (`gh api repos/<o>/<r>/contents/<path>`).
  A frontend built elsewhere (a Vercel check on its PRs) is not on the VPS; a
  Dependabot alert on its lockfile is reported apart.
- **Vulnerabilities in the running image**: `trivy image -q --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --format json <image>`
  on the host, for every app image. Split the result into the app's own
  packages (Python, npm) and the OS layer of the base image.
- **Alerts and pending updates**: `gh api "repos/<o>/<r>/dependabot/alerts?state=open"` and
  `gh pr list -R <o>/<r>`, then for each Renovate or Dependabot PR its CI
  (`gh pr view <n> --json mergeable,statusCheckRollup`). For a failing check,
  name it (`.name // .context`): a Vercel preview, `renovate/artifacts` and a
  test job do not mean the same thing.
- **Repos with no Renovate and no Dependabot**: say so; they get no update PRs
  and need a manual bump.
- **What a grouped PR really changes**: read the diff of every "minor
  updates" or lockfile PR before proposing it. A Python or Node runtime bump
  (`.python-version`, `FROM python:…`, `node-version`) hides in there; a
  green CI does not prove the image builds, since CI may not build it.

GitHub App webhook (Coolify signs the JWT; run in the `coolify` container):

```sh
docker exec coolify php artisan tinker --execute='$j=generateGithubJwt(App\Models\GithubApp::find(<id>)); echo Illuminate\Support\Facades\Http::withToken($j)->get("https://api.github.com/app/hook/config")->body();'
```

`/app/hook/deliveries?per_page=5` on the same token lists recent deliveries
and their status. A URL on a port the host firewall drops means no
deployment fires on merge. Changing it is mine to do in the GitHub UI.

## Phase 2 — Report

One reply, in my language, most urgent first:

1. Health: anything down, unhealthy, full, or already waiting for a reboot.
2. System: pending package count, security items, kernel, Docker.
3. Infra: one table, component / running / latest.
4. Apps: one table, app / app dependencies / OS layer of the image, CRITICAL
   in bold. Then the open update PRs with their CI state, and the repos with
   no update bot.

State only what was checked. Mark a guess as a guess.

## Phase 3 — Plan, then wait

Propose the order below, keeping only the steps that have something to do.
Name what each step disrupts: every merge to the deployed branch triggers a
Coolify deployment to production, a Docker upgrade restarts every container,
and a reboot takes every site down for a few minutes. Then stop and wait for
my approval; I may approve some steps and defer others (the reboot to the
evening, for example).

1. **Apps.** Merge the security PRs whose CI is green, then the lockfile and
   minor-update PRs whose CI is green and whose diff bumps no runtime (a
   runtime bump gets its own PR and a test build), one repo at a time, with the merge
   method the repo allows (`gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed`).
   Before merging, `docker pull` the base images the Dockerfiles name on the
   host, so the build Coolify starts does not reuse a stale cached base and
   the OS layer gets its fixes too. A repo with no update bot: bump the
   vulnerable packages on a branch, open a PR, and propose adding Renovate. A
   base image on an old Debian release: propose the move to the current one
   as its own PR.
2. **Host.** `sudo apt-get update && sudo DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade`,
   then `sudo reboot` if `/var/run/reboot-required` exists. Wait for SSH to
   come back (poll with `ssh -o ConnectTimeout=5`), then check that every
   container from phase 1 is up again.
3. **Infra.** Traefik through Coolify (Servers → Proxy) rather than by
   editing its compose file by hand; images on `latest` pinned to a version;
   host tools from their package source.
4. **Cleanup.** `docker image prune` for images no container uses, after the
   deployments have finished.

Deploying without the webhook, as a forced rebuild (fresh base layers), one
app at a time, waiting for each:

```sh
docker exec coolify php artisan tinker --execute='$a=App\Models\Application::where("uuid","<uuid>")->first(); $u=(string) new Visus\Cuid2\Cuid2(); queue_application_deployment(application: $a, deployment_uuid: $u, force_rebuild: true, no_questions_asked: true); echo $u;'
```

then poll `select status from application_deployment_queues where deployment_uuid='<u>'`
until `finished` or `failed`; the `logs` column holds the build output. A
failed deployment leaves the previous container running.

Traefik's version lives in the proxy configuration Coolify saved
(`servers.proxy->last_saved_proxy_configuration`) and in
`/data/coolify/proxy/docker-compose.yml`: change both, or Coolify puts the
old tag back the next time it writes the proxy.

## Phase 4 — Execute and verify

Work through the approved steps in order. After each deployment, wait for
the new container to become healthy before the next repo. If a deployment
fails or a site stops answering, stop and report; do not chain fixes.

Verification, shown as the commands and the relevant lines of output:

- `docker ps`: every app up, healthy where it has a healthcheck, on the new image.
- `curl -sS -o /dev/null -w '%{http_code}\n' https://<fqdn>` for each FQDN from the Coolify table.
- Trivy again on each new image: the CRITICAL items from the report are gone,
  or the reason they remain.
- `apt list --upgradable` empty or explained, no `/var/run/reboot-required`.

End with a short table: done / deferred / still open. If the session folder
holds VPS notes, update their open items to match.
