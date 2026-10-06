---
name: sre-audit
description: Structured methodology for auditing the reliability and operational maturity of a platform — SLOs, observability, alerting, incident readiness, resilience, change safety, capacity and data safety — with a scoring scale and a client-ready report format. Use whenever the user wants to audit, assess, evaluate, score or benchmark the production-readiness, reliability, SRE maturity or operability of a system, cluster, repo or organization, including at the start of a consulting engagement or before a go-live.
---

# SRE audit methodology

A repeatable engagement-grade audit. Works on a repo, a set of repos, or
interview notes. This skill owns the dimensions, the scoring and the report
format; the `sre-auditor` agent does the reading and gathers the evidence.

## Phase 1 — Scoping

Confirm before digging:

- Systems in scope: services, clusters, environments.
- Available evidence: repos, dashboard exports, alert rules, postmortems, notes.
- The client's trigger: incident trauma, audit requirement, scaling, go-live.
- Deliverable audience: engineering, management, or both.

## Phase 2 — Evidence

Collect file paths, config excerpts and quotes for each dimension. Mark anything
unverifiable as **[not observed]**. Never assume a practice exists because it
should.

| # | Dimension | Look for |
|---|---|---|
| 1 | SLOs & error budgets | SLO definitions; multi-window burn-rate alerts rather than cause-based ones; SLOs as code (Prometheus rules, Cloud Monitoring service SLOs, Sloth, Pyrra) rather than slideware |
| 2 | Observability | Golden signals per service; metrics, logs and traces coverage; cardinality hygiene; dashboards as code; retention; OpenTelemetry rather than vendor lock-in; whether traces are actually sampled and queried |
| 3 | Alerting | Actionable rather than noisy; severity taxonomy; routing; runbook links in the alert body |
| 4 | Incident readiness | Runbook freshness; on-call rotation and escalation; postmortem template and follow-up tracking |
| 5 | Resilience | Timeouts, retries with backoff and jitter, circuit breakers, graceful degradation, multi-zone and multi-region posture, PDBs, HPA and KEDA config |
| 6 | Change safety | CI gates, progressive delivery (canary, blue-green), automated rollback, feature flags, protected branches and required approvals on the GitOps repo |
| 7 | Capacity & cost | Requests and limits against actual usage, autoscaling bounds, quota headroom, single points of failure |
| 8 | Data safety | Backup automation, tested restores, stated RPO and RTO |

Scoring: 1 absent, 2 ad hoc, 3 defined, 4 measured, 5 optimized. Score what is
evidenced, not what is claimed. A control that exists in code but has never run
(a restore job with no successful execution, an alert with no route) scores as
partial, and the report says why.

## Phase 3 — Report

Format it with the `presales-deliverables` skill when it goes to a client.

1. **Executive summary** — overall maturity and the one thing to fix first.
2. **Scorecard** — the 8 dimensions: score, one-line justification.
3. **Top 5 risks** — ranked by likelihood × impact, each as risk, evidence,
   consequence, recommendation.
4. **Quick wins** — achievable in under a week, effort-tagged.
5. **Roadmap 30/60/90** — sequenced, with dependencies and expected score
   movement.
6. **Annex** — the full evidence log.

## Rules

- Vendor-neutral. When naming a tool, give two options and a selection criterion.
- Every recommendation traces back to a finding. No generic best-practice padding.
- Findings describe systems, not people.
- Say when a finding rests on live inspection rather than on code.
