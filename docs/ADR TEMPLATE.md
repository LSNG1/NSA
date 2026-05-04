# ADR-XXX Titre de la decision

| Statut | Date | Equipe |
| --- | --- | --- |
| Propose / Accepte / Remplace / Rejete | Mois AAAA | PAR_1 |

## 1. Contexte

Decrire le probleme, la contrainte ou le besoin qui force une decision.

Inclure les elements importants :

- Objectif du sujet ou du ticket concerne.
- Contraintes non negociables.
- Dependances avec les autres composants.
- Risques connus ou blockers.
- Etat actuel de l'implementation si la decision documente un changement deja fait.

## 2. Decision

Decrire clairement la decision retenue.

| Element | Valeur |
| --- | --- |
| Composant concerne | A completer |
| Site / zone | A completer |
| Technologie retenue | A completer |
| Responsable / owner | A completer |
| Ticket lie | TXX |

Expliquer en quelques paragraphes ce qui sera fait, ou ce qui a ete fait, et comment cela s'integre dans l'architecture globale.

## 3. Options evaluees

| Option | Statut | Motif |
| --- | --- | --- |
| A - Option retenue | Retenue | Pourquoi cette option est la meilleure pour le projet. |
| B - Alternative 1 | Rejetee | Pourquoi elle n'est pas retenue. |
| C - Alternative 2 | Rejetee | Pourquoi elle n'est pas retenue. |

## 4. Flux autorises

Lister les flux reseau ou operationnels crees par cette decision.

| Source | Destination | Port | Protocole | Justification |
| --- | --- | --- | --- | --- |
| A completer | A completer | A completer | TCP/UDP/ICMP | A completer |

Flux bloques ou interdits :

- A completer.
- A completer.

## 5. Configuration de securite

Lister les controles de securite attendus.

| Controle | Decision | Justification |
| --- | --- | --- |
| Authentification | A completer | A completer |
| Autorisation | A completer | A completer |
| Logs | A completer | A completer |
| Secrets | A completer | A completer |
| Firewall | A completer | A completer |

Extraits de configuration si utile :

```text
# Exemple ou placeholder
```

## 6. Exploitation et reprise

Decrire comment operer, depanner ou reconstruire le composant.

- Procedure de verification : A completer.
- Procedure de rollback : A completer.
- Procedure de reprise apres incident : A completer.
- Impact si le composant est indisponible : A completer.

Ordre de reconstruction si applicable :

1. A completer.
2. A completer.
3. A completer.

## 7. Consequences

| Benefices | Risques & mitigations |
| --- | --- |
| A completer | A completer |
| A completer | A completer |

## 8. References

- Sujet CIA T-NSA-820-PAR_1.
- Ticket GitHub : TXX.
- ADR liees : ADR-XXX.
- Fichiers lies : `chemin/vers/fichier`.
