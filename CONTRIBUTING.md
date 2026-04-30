# Contributing Guide — T-NSA-810

## Branches
- `main` — branche stable, jamais de push direct
- `feature/T[ID]-description` — une branche par ticket
- `fix/T[ID]-description` — pour les corrections

## Workflow
1. Créer une branche depuis main : `git checkout -b feature/T10-ansible`
2. Faire ses modifications
3. Commiter : `git commit -m "T10 - description courte"`
4. Pousser : `git push origin feature/T10-ansible`
5. Ouvrir une Pull Request vers main
6. Un autre membre de l'équipe review et merge

## Format des commits
T[ID] - action courte en français
Exemples :
- T10 - init structure Ansible
- T11 - ajout provider Proxmox Terraform
- T12 - ajout pipeline CI lint

## Règles
- Jamais de mot de passe dans le code
- Jamais de push direct sur main
- Tout changement d'architecture mis à jour dans docs/
