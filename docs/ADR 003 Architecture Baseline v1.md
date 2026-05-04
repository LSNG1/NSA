# ADR-003 Architecture Baseline v1 : topology, VM placement, segmentation et recovery

| Statut | Date | Equipe |
| --- | --- | --- |
| Accepte | Mai 2026 | PAR_1 |

## 1. Contexte

Le sujet demande une infrastructure hybride composee de deux sites Proxmox :

- Site 1 : site principal / on-premise.
- Site 2 : site distant / remote.
- Interconnexion site-a-site securisee par VPN.
- Firewalls sur les deux sites avec capacite de coupure d'urgence.
- Acces externe au site distant via un bastion.
- IPAM centralise avec NetBox.
- Centralisation des logs avec Elasticsearch.
- Site web accessible uniquement depuis le reseau interne.
- Architecture extensible pour ajouter d'autres sites.

Contraintes structurantes :

- 3 VMs maximum par site Proxmox.
- Les flux doivent etre limites par defaut et explicitement autorises.
- Les choix doivent rester reproductibles via GitOps, Terraform/OpenTofu et Ansible.
- Les procedures de reprise ne doivent pas creer de deadlock : le bastion doit rester disponible pour reparer le site distant si le VPN tombe.

## 2. Decision

L'architecture de reference retient deux sites routables separes, chacun protege par pfSense, avec un VPN site-a-site entre les firewalls.

Les services sont consolides pour respecter la limite de 3 VMs par site :

| Site | VM | Adresse | Role principal | Roles secondaires |
| --- | --- | --- | --- | --- |
| S1 | vm1-pfsense-s1 | 10.1.0.1 | Firewall, routage, terminaison VPN S1 | DNS forwarding S1 |
| S1 | vm2-elastic-s1 | 10.1.0.20 | Elasticsearch / observabilite | Reception logs Beats |
| S1 | vm3-netbox-s1 | 10.1.0.30 | NetBox / IPAM | Source of truth reseau |
| S2 | vm1-pfsense-s2 | 10.2.0.1 | Firewall, routage, terminaison VPN S2 | DNS forwarding S2, kill switch |
| S2 | vm2-bastion-s2 | 10.2.0.20 | Bastion SSH | Acces admin distant, logs SSH |
| S2 | vm3-vault-s2 | 10.2.0.30 | Vault / secrets | Hebergement possible du web interne si aucun slot VM dedie n'est disponible |

Le site web interne ne recoit pas de VM dediee. Pour respecter la contrainte des 3 VMs par site, il doit etre deployee comme service ou conteneur sur une VM existante. Le placement cible doit etre confirme dans l'inventaire Ansible avant implementation.

## 3. Options evaluees

| Option | Statut | Motif |
| --- | --- | --- |
| A - Deux sites segmentes avec pfSense, OpenVPN, bastion et services consolides | Retenue | Respecte le sujet, garde les frontieres reseau explicites, reste compatible avec 3 VMs par site et permet l'ajout de futurs sites. |
| B - Reseau plat entre toutes les VMs | Rejetee | Trop expose, pas de controle clair des flux, non conforme aux attentes firewall/segmentation. |
| C - Acces distant uniquement via VPN | Rejetee | Cree un deadlock si le VPN tombe : impossible de reparer S2 sans autre chemin d'administration. |
| D - Service dedie par VM | Rejetee | Depasse la limite de 3 VMs par site. |
| E - Mesh VPN tiers pour tous les sites | Rejetee | Ajoute une dependance externe et contourne le besoin de maitriser les firewalls, routes et logs. |

## 4. Flux autorises

Tout flux non liste doit etre bloque par defaut au niveau pfSense ou firewall local.

| Source | Destination | Port | Protocole | Justification |
| --- | --- | --- | --- | --- |
| Internet admin | vm2-bastion-s2 | 22 | TCP | Acces SSH externe controle au site distant. |
| vm2-bastion-s2 | VMs S2 | 22 | TCP | Administration via ProxyJump, sans exposition directe des VMs internes. |
| vm1-pfsense-s1 | vm1-pfsense-s2 | 1194 | UDP | Tunnel OpenVPN site-a-site, port a ajuster si la configuration finale differe. |
| Reseau S1 | Reseau S2 | Selon service | TCP/UDP | Flux internes autorises uniquement via le VPN et les regles pfSense. |
| VMs S1/S2 | vm2-elastic-s1 | 5044 | TCP | Envoi des logs Beats/Filebeat vers Elasticsearch. |
| Automation runner / admin | vm3-netbox-s1 | 443 | TCP | Consultation et mise a jour IPAM via API ou UI NetBox. |
| Clients internes | Service web interne | 80/443 | TCP | Acces au site web uniquement depuis les reseaux internes ou via VPN. |
| pfSense S1 | pfSense S2 | 53 | TCP/UDP | DNS forwarding inter-sites. |

Flux bloques explicitement :

- Internet vers VMs internes S1/S2.
- Internet vers NetBox, Elasticsearch, Vault ou le site web interne.
- SSH direct vers les VMs S1/S2 hors bastion.
- Flux inter-sites si le VPN est coupe, sauf exception de reprise documentee.

## 5. Segmentation et principes de securite

Les zones de confiance sont les suivantes :

| Zone | Contenu | Principe |
| --- | --- | --- |
| WAN | Internet, acces externe admin | Surface minimale : VPN et bastion uniquement. |
| Admin | Bastion, acces SSH, automation | Authentification par cle, logs obligatoires, pas de mot de passe en clair. |
| Services | NetBox, Elasticsearch, Vault, web interne | Acces limite aux ports necessaires et aux sources connues. |
| Inter-site | Tunnel OpenVPN entre pfSense | Routage controle, logs et regles explicites. |

Regles de securite retenues :

- Default deny sur les firewalls.
- Pas de secret dans Git.
- SSH root interdit.
- Acces admin au site distant via bastion.
- Logs SSH, firewall et services envoyes vers Elasticsearch quand le lien est disponible.
- NetBox sert de source de verite pour les prefixes, IPs, roles et inventaires.

## 6. Recovery principles

Les principes de reprise sont :

- Le bastion S2 reste joignable meme si le VPN inter-site est coupe.
- Le kill switch pfSense-S2 bloque les flux inter-sites non autorises quand le VPN est down.
- Les configurations critiques doivent etre versionnees dans Git.
- Les secrets restent hors repo et sont recuperes via Vault, Ansible Vault ou stockage hors-bande documente.
- La reconstruction suit l'ordre minimal suivant :
  1. pfSense S1/S2 et routage de base.
  2. VPN site-a-site.
  3. Bastion S2.
  4. NetBox et inventaire.
  5. Elasticsearch et collecte de logs.
  6. Services internes restants.

## 7. Consequences

| Benefices | Risques & mitigations |
| --- | --- |
| Topologie lisible et compatible avec les livrables du sujet. | Co-localisation de services due a la limite de 3 VMs : documenter la charge et isoler par firewall local/conteneurs. |
| Acces distant recuperable via bastion meme si le VPN tombe. | Bastion critique : durcissement SSH, fail2ban, logs et rotation des cles. |
| NetBox peut devenir la source de verite pour Ansible et les schemas reseau. | Drift possible entre NetBox, inventaire et etat reel : synchronisation et validation a automatiser. |
| Observabilite centralisee sur S1. | Logs retardes si VPN down : buffer local Filebeat et reprise automatique. |
| Architecture extensible a un troisieme site. | Nouveaux sites doivent reutiliser les conventions de nommage, prefixes, roles et regles. |

## 8. References

- Sujet CIA T-NSA-820-PAR_1 : objectifs, contraintes et livrables.
- ADR-001 Bastion Host : hardening SSH et integration kill switch.
- ADR-002 GitOps Workflow : methodologie repo, PR et CI/CD.
- `ansible/inventory/hosts.ini` : placement actuel des VMs et adresses.
- `terraform/site1` et `terraform/site2` : socle provider Proxmox.
