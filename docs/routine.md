# Ma routine Claude Code

Ce qui change au quotidien avec cette config. Une ligne par habitude.

## Au démarrage d'une session

| Avant | Maintenant |
|---|---|
| `claude` dans le repo | `claude -w <nom>` pour toute tâche qui peut tourner en parallèle d'une autre (un worktree par session) |
| Vérifier à la main le projet gcloud et le contexte kube | Lire la statusline : `gcp:<projet>` et `k8s:<cluster>` s'affichent en permanence |
| Rien | `/effort low` pour itérer vite, `/effort xhigh` pour un bug difficile, `ultrathink` pour une seule question |

## Pendant le travail

| Avant | Maintenant |
|---|---|
| « Fais-le avec l'agent iac-engineer » | Laisser Claude travailler directement. Les agents servent à paralléliser, isoler de longues sorties ou relire avec un œil neuf |
| Rappeler de formater | Rien à faire : `tofu fmt` et `terragrunt hcl fmt` passent après chaque édition, `ruff`/`prettier` quand le projet les utilise |
| Lancer `tofu validate` pour voir les erreurs | Claude voit les diagnostics `terraform-ls`, `yaml-language-server` et `pyright` juste après chaque édition |
| Surveiller qu'il ne lance pas un `apply` | Les formes courantes de commandes qui modifient (`kubectl apply/delete/exec`, `helm upgrade`, `tofu apply`, `gcloud … delete`, `glab mr merge/approve`, `vault write`…) demandent ton accord, même en auto mode. Une variante exotique (`sh -c …`) peut passer : le sandbox (`/sandbox`) couvre ce cas |
| Corriger trois fois la même dérive | `Esc` dès qu'il dérive. Après deux corrections ratées : `/clear` et un meilleur prompt |
| Une question rapide qui pollue le fil | `/btw <question>` |
| Une tâche longue qui bloque le terminal | `/background`, puis `claude agents` pour suivre |

## Définir « terminé »

| Avant | Maintenant |
|---|---|
| « C'est bon ? » | Exiger la preuve : la commande lancée et sa sortie (le style `Pro` le demande déjà) |
| Tâche longue sans surveillance | `/goal <condition vérifiable>`, par exemple `/goal tofu validate passe et le plan ne détruit rien` |
| Rien dans le repo client | Copier `templates/settings.json.template` en `.claude/settings.json` et remplacer `REPLACE_WITH_CHECK` par la vérification du projet : Claude ne peut plus s'arrêter tant qu'elle échoue |

## Avant une MR

1. `/learn` si la session a appris quelque chose d'important : rangé tout de suite, avec toi. Sinon rien à faire, la fin de session le note dans la boîte (voir plus bas).
2. `/commit` : découpe en commits Angular. Seul toi peux le lancer.
3. `/code-review` (ou l'agent `code-reviewer`) : relecture par un regard qui n'a pas vu le raisonnement.
4. `/security-review` si la MR touche à l'auth, aux secrets ou à l'IAM.

## Nouveau projet client

```sh
cp ~/Private/dotfiles-claude/templates/AGENTS.md.template AGENTS.md
```

Claude Code lit `AGENTS.md` directement tant que le repo n'a pas de
`CLAUDE.md`. S'il en a déjà un, y ajouter la ligne `@AGENTS.md`.

Remplir `AGENTS.md` (60 lignes max, seulement ce que Claude ne peut pas deviner
en lisant le code). Puis, dans une session, `/auto-mode-setup` pour que l'auto
mode connaisse l'infra du client.

## Livrables (présales, docs)

1. « Interview me until you could write the spec, then write SPEC.md ».
2. Nouvelle session (`/clear`) pour produire à partir du `SPEC.md`.
3. Faire relire contre le `SPEC.md` en ajoutant « skip style ».
4. Écrire « be ambitious » quand tu veux la version complète.

## Entretien de la config (une fois par semaine)

| Commande | Pour |
|---|---|
| `./install.sh --check` | Vérifier que `~/.claude` est identique au repo. Si non : `./install.sh`. Une règle retirée du fragment se retire aussi à la main de `~/.claude/settings.json` |
| `/insights` | Voir où les sessions coincent |
| `/learn review` | Vider `~/.claude/learnings/inbox/` (rempli à chaque fin de session par le hook `SessionEnd`), promouvoir dans ce repo les mémoires valables partout, vérifier les plus anciennes |
| `/skill-doctor` | Repérer les skills qui coûtent du contexte sans servir |
| `/usage` | Voir quels agents consomment le plus |
| `/doctor prompt-audit` | Trouver les consignes obsolètes ou contradictoires |

Une règle que Claude rate deux fois va dans `home/CLAUDE.md` (`/learn` le
propose). Une règle qui ne souffre aucune exception va dans
`home/settings.base.json` (deny/ask) ou dans un hook, pas dans le texte.
