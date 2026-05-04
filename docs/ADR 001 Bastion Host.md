# ADR-001 Bastion Host SSH : hardening SSH et integration kill switch

| Statut | Date | Equipe |
| --- | --- | --- |
| Accepte | Mars 2026 | PAR_1 |

## 1. Contexte

Le sujet impose un acces externe securise au Site 2, le site distant. Les VMs de S2 ne sont pas joignables directement depuis Internet.

Contraintes structurantes :

- 3 VMs maximum sur S2 : le bastion occupe un slot et doit rester sobre en ressources.
- Kill switch pfSense : si le tunnel VPN est coupe, le bastion doit rester joignable pour permettre la reprise.
- Observabilite : les logs SSH alimentent Elasticsearch sur S1 via Filebeat.
- Reproductibilite : la solution doit etre automatisee avec Ansible pour les sites futurs.

## 2. Decision

Le point d'entree externe du site distant est une VM Debian 12 durcie, deployee sur Proxmox S2.

| Element | Valeur |
| --- | --- |
| Nom cible | `vm2-bastion-s2` |
| Adresse cible | `10.2.0.20` |
| OS | Debian 12 Bookworm |
| Acces externe | SSH uniquement |
| Acces interne | ProxyJump SSH vers les VMs S2 autorisees |
| Logs | Filebeat vers Elasticsearch S1 |

Le bastion est le seul point d'entree externe vers S2. Tout acces administratif aux VMs internes de S2 transite par `ProxyJump SSH`.

Le bastion doit fonctionner independamment du tunnel OpenVPN. Il reste donc atteignable meme si le tunnel inter-site est coupe, afin de permettre la reprise ou la reconfiguration de pfSense-S2.

## 3. Options evaluees

| Option | Statut | Motif |
| --- | --- | --- |
| A - Bastion SSH Debian 12 hardened | Retenue | Compatible sujet, independant du VPN, Filebeat natif, automatisable avec Ansible. |
| B - Acces via tunnel VPN uniquement | Rejetee | Deadlock si le VPN est down : plus aucun acces S2 pour reparer le tunnel. |
| C - Tailscale ou mesh WireGuard tiers | Rejetee | Dependance tiers, redondant avec OpenVPN, pas de log centralise natif dans le perimetre du sujet. |

## 4. Flux autorises

| Source | Destination | Port | Protocole | Justification |
| --- | --- | --- | --- | --- |
| Internet admin | Bastion-S2 | 22 | TCP | Acces admin externe controle. |
| Bastion-S2 | pfSense-S2 (`10.2.0.1`) | 22 | TCP | Administration firewall S2 via ProxyJump. |
| Bastion-S2 | Services-S2 | 22 | TCP | Administration services S2 via ProxyJump. |
| Bastion-S2 | Elasticsearch-S1 (`10.1.0.20`) | 5044 | TCP | Envoi logs Filebeat. |

Flux bloques :

- Acces direct Internet vers les VMs internes S2.
- SSH root.
- Authentification par mot de passe.
- TCP forwarding arbitraire.
- X11 forwarding.

## 5. Configuration de securite

Extraits cibles de `sshd_config` :

```text
Protocol 2
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AllowUsers bastion-user
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
X11Forwarding no
AllowTcpForwarding no
```

`AllowTcpForwarding no` est conserve pour bloquer les tunnels arbitraires. Les chemins administratifs attendus doivent rester explicites dans les regles SSH, firewall et runbooks.

Stack de durcissement :

| Outil | Role | Configuration cle |
| --- | --- | --- |
| UFW | Firewall local | `deny all`, `allow 22/tcp` depuis les sources admin attendues. |
| Fail2ban | Anti-brute force | 5 tentatives, ban 1h. |
| Filebeat | Export logs SSH | Module system, output vers `10.1.0.20:5044`. |
| auditd | Audit systeme | Regles CIS Level 1 ciblees. |
| unattended-upgrades | Correctifs securite | Mises a jour depuis `security.debian.org`. |

## 6. Kill switch pfSense

Quand le tunnel VPN est down, pfSense-S2 bloque le trafic inter-sites. Le bastion doit etre explicitement exclu de cette regle pour rester accessible.

Ordre cible des regles :

```text
# pfSense-S2
WAN ALLOW TCP :22 -> 10.2.0.20  # bastion, toujours joignable, priorite haute
BLOCK any -> LAN S2             # kill switch VPN down, priorite basse
```

## 7. Consequences

| Benefices | Risques & mitigations |
| --- | --- |
| Point d'entree unique, auditable et conforme au sujet. | Brute force SSH : Fail2ban, cle ED25519 obligatoire, restriction des sources si possible. |
| Independant du VPN, donc pas de deadlock de recuperation. | Cles obsoletes : rotation documentee dans le runbook. |
| Automatisable via Ansible. | Log shipping coupe si VPN down : buffer Filebeat local puis reprise. |
| Logs SSH dans Elasticsearch pour detection d'incidents. | Pivot si compromis : pas de root, pas de mot de passe, forwarding limite, auditd. |

## 8. References

- Sujet CIA T-NSA-820-PAR_1 : "Set up a bastion host for external access to the remote site".
- OpenSSH Hardening - Teleport.
- SSH Bastion Host Framework - Medium.
- `ansible/inventory/hosts.ini` : adresse cible actuelle du bastion S2.
