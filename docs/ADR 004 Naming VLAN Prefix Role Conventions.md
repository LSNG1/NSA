# ADR-004 Naming, VLAN, Prefix and Role Conventions

| Statut | Date | Equipe |
| --- | --- | --- |
| Accepte | Mai 2026 | PAR_1 |

## 1. Contexte

Le ticket T03 demande des conventions stables et reutilisables pour le nommage, les VLANs, les prefixes IP et les roles. Ces conventions doivent rester coherentes entre :

- NetBox, comme source de verite reseau.
- Ansible, pour les inventaires, groupes et roles.
- Terraform/OpenTofu, pour le provisioning Proxmox.
- Les schemas d'architecture.
- Les futurs sites ajoutes au projet.

Contraintes structurantes :

- 3 VMs maximum par site Proxmox.
- Deux sites initiaux : S1 on-premise et S2 distant.
- Architecture extensible vers S3, S4, etc.
- Les noms doivent etre lisibles par l'equipe et par les instructeurs.
- Les conventions doivent eviter les collisions entre sites, services et roles.

## 2. Decision

Le projet retient une convention simple basee sur le code de site, le numero de VM et le role principal.

| Element | Convention |
| --- | --- |
| Code site | `s1`, `s2`, puis `s3`, `s4`, etc. |
| Nom VM | `vm<numero>-<role>-<site>` |
| Prefixe site v1 | `10.<numero_site>.0.0/24` |
| Nom groupe Ansible site | `[site1]`, `[site2]`, puis `[site3]` |
| Nom groupe Ansible role | `[pfsense]`, `[bastion]`, `[netbox]`, `[elastic]`, `[vault]`, `[web]` |
| Nom NetBox site | `S1`, `S2`, puis `S3` |
| Nom NetBox device | Identique au hostname VM |
| Nom Terraform root | `terraform/site1`, `terraform/site2`, puis `terraform/site3` |

Conventions actuelles retenues :

| Site | Prefixe v1 | Role | Hostname | Adresse |
| --- | --- | --- | --- | --- |
| S1 | `10.1.0.0/24` | pfSense | `vm1-pfsense-s1` | `10.1.0.1` |
| S1 | `10.1.0.0/24` | Elasticsearch | `vm2-elastic-s1` | `10.1.0.20` |
| S1 | `10.1.0.0/24` | NetBox | `vm3-netbox-s1` | `10.1.0.30` |
| S2 | `10.2.0.0/24` | pfSense | `vm1-pfsense-s2` | `10.2.0.1` |
| S2 | `10.2.0.0/24` | Bastion | `vm2-bastion-s2` | `10.2.0.20` |
| S2 | `10.2.0.0/24` | Vault | `vm3-vault-s2` | `10.2.0.30` |

Le format futur pour un nouveau site est :

```text
Site N      : S<N>
Prefixe v1 : 10.<N>.0.0/24
pfSense    : vm1-pfsense-s<N> -> 10.<N>.0.1
Service A  : vm2-<role>-s<N>  -> 10.<N>.0.20
Service B  : vm3-<role>-s<N>  -> 10.<N>.0.30
```

## 3. Options evaluees

| Option | Statut | Motif |
| --- | --- | --- |
| A - `vm<numero>-<role>-<site>` et `10.<site>.0.0/24` | Retenue | Lisible, deja aligne avec l'inventaire, extensible aux futurs sites. |
| B - Noms courts type `s1-fw1`, `s1-app1` | Rejetee | Moins explicite pour les instructeurs et moins clair dans Ansible/NetBox. |
| C - Noms par fonction sans numero VM | Rejetee | Ne montre pas directement la contrainte des 3 VMs par site. |
| D - Prefixes aleatoires par site | Rejetee | Rend les schemas, routes, firewalls et futurs sites plus difficiles a maintenir. |

## 4. VLANs et zones reseau

La version actuelle utilise un prefixe simple par site (`10.<site>.0.0/24`). Les VLANs ci-dessous sont reserves comme convention cible si la segmentation est implementee dans Proxmox/pfSense.

| Zone | VLAN ID cible | Prefixe cible | Usage |
| --- | --- | --- | --- |
| Admin | `10` | `10.<site>.10.0/24` | Bastion, SSH, automation, administration. |
| Services | `20` | `10.<site>.20.0/24` | NetBox, Elasticsearch, Vault, web interne. |
| DMZ | `30` | `10.<site>.30.0/24` | Services exposes de maniere controlee. |
| Transit VPN | `40` | `10.<site>.40.0/24` | Interfaces ou routes liees au VPN. |
| Management Proxmox | `99` | `10.<site>.99.0/24` | Administration hyperviseur si separee. |

Regles :

- Les VLANs doivent garder les memes IDs sur tous les sites.
- Le numero de site reste dans le deuxieme octet IP.
- Une zone non implementee ne doit pas apparaitre comme active dans les schemas.
- Si la segmentation reste logique uniquement, les documents doivent l'indiquer clairement.

## 5. Roles et groupes

Roles standards :

| Role | Nom court | Description |
| --- | --- | --- |
| pfSense | `pfsense` | Firewall, routage, VPN, DNS forwarding. |
| Bastion | `bastion` | Point d'entree SSH externe controle. |
| NetBox | `netbox` | IPAM / source of truth. |
| Elasticsearch | `elastic` | Centralisation et recherche de logs. |
| Vault | `vault` | Gestion des secrets. |
| Web interne | `web` | Site web accessible uniquement en interne. |

Groupes Ansible recommandes :

```ini
[site1]
vm1-pfsense-s1
vm2-elastic-s1
vm3-netbox-s1

[site2]
vm1-pfsense-s2
vm2-bastion-s2
vm3-vault-s2

[pfsense]
vm1-pfsense-s1
vm1-pfsense-s2

[observability]
vm2-elastic-s1

[ipam]
vm3-netbox-s1

[bastion]
vm2-bastion-s2

[secrets]
vm3-vault-s2
```

## 6. NetBox conventions

NetBox doit utiliser les memes noms que l'inventaire et les schemas.

| Objet NetBox | Convention |
| --- | --- |
| Site | `S1`, `S2`, `S3` |
| Region | `PAR_1` |
| Device name | Hostname exact : `vm2-bastion-s2` |
| Role device | `pfsense`, `bastion`, `netbox`, `elastic`, `vault`, `web` |
| Prefix | `10.<site>.0.0/24` en v1 |
| VLAN | `S<site>-<zone>-VLAN<ID>` si VLAN implemente |
| IP address description | `<hostname> - <interface/role>` |

Exemple :

```text
Site       : S2
Device     : vm2-bastion-s2
Role       : bastion
IP         : 10.2.0.20/24
Prefix     : 10.2.0.0/24
Description: vm2-bastion-s2 - ssh admin entrypoint
```

## 7. Consequences

| Benefices | Risques & mitigations |
| --- | --- |
| Les noms sont lisibles et directement relies au site, au role et au numero de VM. | Renommer une VM apres implementation peut casser Ansible/NetBox : documenter et faire via PR. |
| Le plan IP permet d'ajouter S3 sans redesign. | Le `/24` v1 est moins segmente : VLANs reserves pour evolution. |
| NetBox, Ansible, Terraform et schemas peuvent utiliser les memes identifiants. | Drift entre outils : NetBox doit devenir la source de verite et l'inventaire doit etre synchronise. |
| Les roles restent comprehensibles pour les instructeurs. | Co-localisation possible du web interne : documenter le role secondaire dans NetBox et Ansible. |

## 8. References

- Ticket GitHub : T03 - Define naming, VLAN, prefix, and role conventions.
- ADR-003 Architecture Baseline v1 : placement des VMs et principes de segmentation.
- `ansible/inventory/hosts.ini` : inventaire actuel.
- `terraform/site1` et `terraform/site2` : structure actuelle par site.
