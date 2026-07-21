---
name: sre-audit
description: Structured methodology for auditing the reliability and operational maturity of a platform — SLOs, observability, alerting, incident readiness, resilience, change safety, capacity and data safety. Use this skill whenever the user wants to audit, assess, evaluate or benchmark the production-readiness, reliability, SRE maturity or operability of a system, cluster, repo or organization, including at the start of a consulting engagement or before a go-live.
---

# SRE audit methodology

A repeatable engagement-grade audit. Works on a repo, a set of repos, or interview notes. Delegate repo exploration to the `sre-auditor` agent when available; this skill governs method and report format.

## Phase 1 — Scoping (always first)

Establish and confirm with the user before digging:
- Systems in scope (services, clusters, environments)
- Available evidence: repos, dashboards exports, alert rules, postmortems, interview notes
- The client's trigger: incident trauma, audit requirement, scaling, go-live?
- Deliverable audience: engineering, management, or both

## Phase 2 — Evidence collection

For each dimension below, collect evidence (file paths, config excerpts, quotes from notes). Mark anything unverifiable as **[not observed]** — never assume practices exist because they should.

| # | Dimension | Look for |
|---|-----------|----------|
| 1 | SLOs & error budgets | SLO definitions, burn-rate alerts vs cause-based alerts |
| 2 | Observability | Golden signals coverage, dashboards-as-code, traces, log hygiene |
| 3 | Alerting | Actionability, severity taxonomy, runbook links, noise signals |
| 4 | Incident readiness | Runbooks freshness, on-call setup, postmortem templates & follow-up |
| 5 | Resilience | Timeouts/retries/backoff, PDB, HPA, multi-zone, degradation modes |
| 6 | Change safety | CI gates, progressive delivery, rollback automation, GitOps drift |
| 7 | Capacity & cost | Requests vs usage, autoscaling bounds, SPOFs, cost anomalies |
| 8 | Data safety | Backup automation, restore tests, RPO/RTO |

Scoring: 1 = absent, 2 = ad hoc, 3 = defined, 4 = measured, 5 = optimized. Score what is evidenced, not what is claimed.

## Phase 3 — Report

Structure (combine with the `presales-deliverables` skill for client formatting):
1. **Executive summary** — overall maturity, the one thing to fix first
2. **Scorecard** — table of the 8 dimensions: score, one-line justification
3. **Top 5 risks** — ranked likelihood × impact, each: risk → evidence → consequence → recommendation
4. **Quick wins** — achievable in under a week, effort-tagged
5. **Roadmap 30/60/90** — sequenced, with dependencies and expected score movement
6. **Annex** — full evidence log

## Rules

- Vendor-neutral recommendations; when naming tools, give two options and a selection criterion.
- Every recommendation traceable to a finding; no generic best-practice padding.
- Tone: factual, non-blaming — findings describe systems, not people.
