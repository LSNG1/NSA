# ADR-002 GitOps Workflow : methodologie, repository et CI/CD

| Statut | Date | Equipe |
| --- | --- | --- |
| Accepte | Mars 2026 | PAR_1 |

## 1. Contexte et definition

Le sujet impose des depots GitOps accessibles aux instructeurs et evalue la qualite et la lisibilite du code. La CI/CD est listee comme bonus, mais la detection de secrets et la validation des fichiers IaC reduisent le risque des les premiers follow-ups.

Contraintes structurantes :

- GitHub est utilise comme support GitOps et comme trace d'evaluation.
- L'equipe est heterogene : Git est connu, mais les Pull Requests, reviews, Terraform/OpenTofu, Ansible et Proxmox sont nouveaux pour certains membres.
- Pas de CD automatique au demarrage : l'application des changements reste manuelle au Follow-up 1.
- Risque secrets : tokens NetBox, certificats OpenVPN, cles SSH et mots de passe Proxmox ne doivent jamais apparaitre dans l'historique Git.

## 2. Decision

Le workflow retenu est :

1. Monorepo GitHub avec separation claire `docs/`, `terraform/` et `ansible/`.
2. Branche `main` stable : pas de push direct, modifications via Pull Request.
3. Une branche par ticket : `feature/T[ID]-description` ou `fix/T[ID]-description`.
4. Commits au format `T[ID] - action courte`.
5. CI GitHub Actions sur Pull Request et push vers `main`.
6. Application manuelle des changements d'infrastructure au debut du projet.

## 3. Options de workflow evaluees

| Option | Statut | Motif |
| --- | --- | --- |
| A - Feature branch + Pull Request obligatoire | Retenue | Tracabilite complete, CI automatique sur PR, pedagogique pour l'equipe, historique lisible par les instructeurs. |
| B - Push direct sur main | Rejetee | Aucune tracabilite, pas de controle pre-merge, aucun filet contre les secrets commites. |
| C - Gitflow complet (`develop`, `release`, `hotfix`) | Rejetee | Surcharge cognitive injustifiee : le projet n'a qu'un seul environnement cible. |

## 4. Structure

Structure cible du repository :

```text
.
|-- .github/
|   |-- PULL_REQUEST_TEMPLATE.md
|   `-- workflows/
|       `-- ci.yml
|-- ansible/
|   |-- ansible.cfg
|   |-- inventory/
|   |-- playbooks/
|   `-- roles/
|-- docs/
|   |-- ADR 001 Bastion Host.md
|   |-- ADR 002 GitOps Workflow.md
|   `-- ADR 003 Architecture Baseline v1.md
|-- terraform/
|   |-- site1/
|   `-- site2/
|-- CONTRIBUTING.md
`-- README.md
```

Politique de branches :

| Branche | Usage | Protection |
| --- | --- | --- |
| `main` | Etat stable valide de l'infrastructure | PR obligatoire, review attendue. |
| `feature/T[ID]-description` | Nouvelle fonctionnalite ou composant | Merge via PR. |
| `fix/T[ID]-description` | Correction de configuration | Merge via PR. |
| `docs/T[ID]-description` | Documentation uniquement | Merge via PR. |

Convention de commits :

```text
T10 - init structure Ansible
T11 - ajout provider Proxmox Terraform
T12 - ajout pipeline CI lint
T20 - ajout configuration reseau VM1 site1
```

## 5. CI/CD

Le pipeline actuel est `.github/workflows/ci.yml`.

Perimetre retenu :

| Controle | Objectif |
| --- | --- |
| Blocage fichiers secrets ou etat local | Refuser `.pem`, `.key`, `.p12`, `.pfx`, `.tfstate`, `.tfvars`. |
| `terraform fmt -check -recursive` | Garder un format Terraform coherent. |
| `ansible-playbook --syntax-check` | Detecter les erreurs syntaxiques dans les playbooks. |

Perimetre non retenu au demarrage :

| Option | Statut | Motif |
| --- | --- | --- |
| `tofu validate` avec providers reels | A ajouter plus tard | Peut bloquer si les variables/provider Proxmox ne sont pas disponibles en CI. |
| `ansible-lint` | A ajouter plus tard | Utile, mais peut generer beaucoup de bruit tant que les roles sont des squelettes. |
| Checkov ou tfsec | Bonus futur | Interessant pour DevSecOps, mais faux positifs probables sur une infra en construction. |
| CD automatique | Rejete au FW1 | Les changements restent appliques manuellement pour garder le controle. |

## 6. Gestion des secrets

| Type de secret | Stockage retenu |
| --- | --- |
| Tokens NetBox API | Variable d'environnement locale ou Ansible Vault. |
| Certificats OpenVPN / PKI | Repertoire local hors repo, couvert par `.gitignore`. |
| Cles SSH privees | Jamais dans le repo, distribution hors-bande entre membres. |
| Mots de passe Proxmox | Ansible Vault ou variable locale sensible, mot de passe Vault hors repo. |
| Terraform state | Hors repo, jamais committe. |

Regles :

- Aucun secret en clair dans Git.
- Aucun `.tfvars` personnel dans Git.
- Les exemples doivent utiliser des placeholders explicites.
- Toute fuite doit etre traitee par suppression, rotation et documentation de l'incident.

## 7. Consequences

| Benefices | Risques & mitigations |
| --- | --- |
| Audit trail complet : qui a change quoi, quand et pourquoi. | Git peu maitrise : `CONTRIBUTING.md` documente les commandes et conventions. |
| Les PR deviennent un vecteur d'apprentissage et de review. | Reviewer indisponible : delai max 24h, tech lead en fallback. |
| Detection precoce de fichiers secrets ou etat local. | Faux positifs sur exemples : preferer placeholders et exceptions documentees si besoin. |
| Structure evolutive : checks CI additionnels sans refonte. | Apply manuel : acceptable au Follow-up 1, a automatiser ensuite si l'equipe valide. |

## 8. References

- Sujet CIA T-NSA-820-PAR_1 : setup of GitOps repositories, bonus CI/CD integration.
- GitOps Principles : `gitops.tech`.
- Conventional Commits : `conventionalcommits.org` pour reference, meme si le projet retient le format ticket `T[ID]`.
- gitleaks : `github.com/gitleaks/gitleaks`.
- `.github/workflows/ci.yml` : pipeline CI actuel.
- `CONTRIBUTING.md` : workflow, branches et commits.
