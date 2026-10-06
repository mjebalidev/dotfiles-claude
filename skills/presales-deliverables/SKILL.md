---
name: presales-deliverables
description: Produce consulting pre-sales deliverables — proposals, statements of work, RFP/RFI answers, audit reports, discovery syntheses and executive one-pagers — with consistent structure and tone. Use this skill whenever the user asks to draft, structure or review a proposal, SOW, offre, proposition commerciale, réponse à appel d'offres, compte-rendu de discovery, or any client-facing consulting document, even if they just paste raw notes and ask to "clean this up for the client".
---

# Pre-sales deliverables

Turn raw material (call notes, audit findings, emails) into client-ready consulting documents.

## Universal rules

1. Identify the document type first (proposal, SOW, RFP answer, audit report, one-pager). If ambiguous, ask one question.
2. Match the language of the client material (French or English) unless told otherwise.
3. Executive summary always first, max half a page: client's stake → what we propose → outcome → effort/timeline range.
4. Facts vs assumptions: anything not stated by the client goes in an "Assumptions & prerequisites" section. Never invent client names, volumes, budgets or dates.
5. Quantify wherever honest: current pain (incidents/month, MTTR, cost) vs target. If no numbers exist, propose measuring them as a first step.
6. No superlatives, no buzzword chains. One differentiator argued well beats five asserted. Tone: the `humanizer` skill.
7. Pricing: structure and drivers only (per workstream, T&M vs fixed), figures as placeholders like `[X]` unless the user provides rates.

## Structures by type

**Proposal / Offre**
1. Contexte & enjeux (the client's words, reformulated)
2. Objectifs & critères de succès (measurable)
3. Démarche proposée — 2-3 options with a recommendation
4. Architecture / solution (Mermaid diagram if technical)
5. Plan de délivery: phases, jalons, livrables per phase
6. Équipe & gouvernance (roles, rituals)
7. Hypothèses & prérequis
8. Structure tarifaire

**Statement of Work**: scope IN / scope OUT (explicit), deliverables with acceptance criteria, planning, client responsibilities, change-request process. Precision over persuasion.

**RFP answer**: per question — restate in one line, direct answer first sentence, then approach/evidence, then differentiator. Respect imposed formats and word limits strictly.

**Audit report**: structure and scoring come from the `sre-audit` skill. This skill governs the client-facing layer only: executive summary, vocabulary, assumptions.

**Executive one-pager**: problem → cost of inaction → proposed move → proof → next step (a meeting, a scoped assessment). 250 words max.

## Quality gate before returning

- [ ] Exec summary readable by a non-technical sponsor in under a minute
- [ ] Every claim is either client-sourced, evidenced, or listed as an assumption
- [ ] A clear, low-friction next step is proposed
- [ ] Scope boundaries explicit (for proposals/SOW)
- [ ] Consistent terminology with the client's vocabulary
