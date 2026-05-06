# Contributing Guide - T-NSA-820

## Branches
- `main` - branche stable, jamais de push direct
- `feature/T[ID]-description` - nouvelle fonctionnalite ou composant
- `fix/T[ID]-description` - correction
- `docs/T[ID]-description` - documentation uniquement

## Workflow
1. Verifier que le ticket existe et contient une Definition of Done claire.
2. Creer une branche depuis main : `git checkout -b feature/T10-ansible`
3. Faire ses modifications
4. Commiter : `git commit -m "T10 - description courte"`
5. Pousser : `git push origin feature/T10-ansible`
6. Ouvrir une Pull Request vers main
7. Remplir le template PR : tests, evidence, risques, rollback
8. Un autre membre de l'equipe review
9. Merger seulement si la CI est verte ou si l'ecart est explique
10. Fermer le ticket quand la PR est mergee et que la Definition of Done est satisfaite

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
- Tout changement reseau doit indiquer les flux autorises, les flux bloques et la preuve de test
- Tout changement de configuration machine doit etre rejouable via Ansible, Terraform/OpenTofu ou documente dans un runbook
- Tout ticket termine doit avoir une preuve : commande, capture, fichier versionne ou explication testable
