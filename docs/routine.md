# Ma routine Claude Code

Ce qui change au quotidien avec cette config. Une ligne par habitude.

## Au démarrage d'une session

| Avant | Maintenant |
|---|---|
| `claude` dans le repo | `claude -w <nom>` pour toute tâche qui peut tourner en parallèle d'une autre (un worktree par session) |
| Vérifier à la main le projet gcloud et le contexte kube | Lire la statusline : `☁ <configuration gcloud>` et `⎈ <contexte>` (ou `⎈ <client> · no context`) s'affichent en permanence |
| Rien | `/effort low` pour itérer vite, `/effort xhigh` pour un bug difficile, `ultrathink` pour une seule question |

## Clients, clusters et comptes cloud

Un dossier par client sous `~/Projects/<client>/`. Le `.envrc` à sa racine
choisit le kubeconfig, la configuration gcloud et les ADC de ce client. En
dehors, gcloud utilise le compte par défaut et kubectl ne voit aucun cluster
client.

| Avant | Maintenant |
|---|---|
| `kubectx` qui change le contexte de tous les terminaux | `cd ~/Projects/<client>` puis `kx` (fzf) ou `kx <contexte>` : le contexte ne vaut que pour ce terminal, `kx -` le retire. Aucun contexte par défaut : un nouveau terminal ne tombe jamais sur la prod |
| Deviner sur quel cluster on est | Prompt et barre de Claude : `☁ <client>` et `⎈ <contexte>`, sur fond rouge en prod, en jaune en test/int. k9s encadre la prod en rouge |
| Un `~/.kube/config` avec tous les clusters | `~/.kube/configs/<client>/config`, régénéré par `kube-sync <client>` à partir de `~/.config/kube/clusters.d/` (fragments du repo privé) |
| `gcloud container clusters get-credentials` | Ajouter le cluster dans l'inventaire (`dns_endpoint`, `internal_ip`, `prod`) puis `kube-sync <client>` |
| `gcloud config set account` selon le client | Rien : `CLOUDSDK_ACTIVE_CONFIG_NAME` suit le dossier |
| Terraform avec les ADC du dernier login | `GOOGLE_APPLICATION_CREDENTIALS` suit le dossier (`adc-<client>.json`). Les ADC expirent : `gcloud auth application-default login --account <compte>` puis recopier le fichier |
| Se souvenir de ne rien toucher en prod | Les contextes `*-prod-*` s'ouvrent en lecture seule dans k9s |
| Expliquer le client à Claude à chaque session | `~/Projects/<client>/CLAUDE.md`, hors du repo, chargé automatiquement |
| Nouveau dossier de travail | Le créer sous le bon `~/Projects/<client>/` : l'identité git (`includeIf`) et l'environnement suivent |

Le contexte d'un client ou de l'employeur vit dans un repo privé par mission,
cloné dans le dossier de la mission et relié par des liens ; on modifie
toujours le fichier dans ce repo, jamais la cible du lien. Ce repo-ci reste
public et générique.

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

Une règle que Claude rate deux fois va dans les règles d'équipe ou dans `home/CLAUDE.md` (`/learn` le
propose). Une règle qui ne souffre aucune exception va dans
`home/settings.base.json` (deny/ask) ou dans un hook, pas dans le texte.
