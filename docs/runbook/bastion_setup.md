# Runbook — Bastion S2 setup

## Purpose

The bastion `bastion-s2` is the single SSH entry point from the Internet 
into the infrastructure. All other VMs are only reachable through it.

## Specifications

- VM Proxmox : 168 (node vm003)
- OS : Ubuntu Server 24.04.3 LTS
- Hostname : bastion-s2
- LAN IP : 10.2.0.5/24
- Gateway : 10.2.0.1 (pfsense-s2)
- Network interface : enp6s18

## Setup steps (manual, to be automated with Ansible later)

### 1. Network configuration

Apply Netplan config from `network/netplan/bastion-s2.yaml` :

```bash
sudo cp bastion-s2.yaml /etc/netplan/01-cia-network.yaml
sudo chmod 600 /etc/netplan/01-cia-network.yaml
sudo netplan apply
```

### 2. Hostname

```bash
sudo hostnamectl set-hostname bastion-s2
sudo sed -i 's/127.0.1.1.*/127.0.1.1\tbastion-s2/' /etc/hosts
```

### 3. Install security packages

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y openssh-server fail2ban rsyslog
```

### 4. Install SSH public key

On the user's local machine, generate a key if not done :
```bash
ssh-keygen -t ed25519 -C "user@example.com" -f ~/.ssh/cia_bastion
```

Copy the public key content (`~/.ssh/cia_bastion.pub`) to the bastion :
```bash
# On bastion, as par1-admin
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "ssh-ed25519 AAAA... user@example.com" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### 5. Apply SSH hardening

```bash
sudo cp ansible/files/bastion/sshd_config.d/99-cia-hardening.conf \
        /etc/ssh/sshd_config.d/

sudo sshd -t           # Validate syntax
sudo systemctl restart ssh
```

### 6. Configure fail2ban

```bash
sudo cp ansible/files/bastion/fail2ban/jail.local /etc/fail2ban/jail.local
sudo systemctl enable --now fail2ban
sudo fail2ban-client status sshd
```

### 7. (TODO) Configure UFW

To be added once stack is stabilized :
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw --force enable
```

## Validation tests

### Test SSH from LAN (from agent-s2)
```bash
ssh par1-admin@10.2.0.5
# Should prompt for password (until NAT external is set up)
```

### Test SSH from Internet (after NAT pfSense S2 is configured)
```bash
ssh -i ~/.ssh/cia_bastion -p 2222 par1-admin@<pfsense-s2-public-ip>
```

### Test fail2ban
```bash
sudo fail2ban-client status sshd
# Should show active jail with 0 banned
```

## Recovery procedures

### Locked out of SSH
1. Connect via Proxmox console (VM 168)
2. Login with par1-admin credentials
3. Edit `/etc/ssh/sshd_config.d/99-cia-hardening.conf` to fix the issue
4. `sudo systemctl restart ssh`

### Fail2ban banned legitimate IP
```bash
sudo fail2ban-client unban <ip>
```

## Maintenance

### View SSH logs
```bash
sudo journalctl -u ssh -f
```

### View fail2ban activity
```bash
sudo journalctl -u fail2ban -f
sudo fail2ban-client status sshd
```

### Update SSH config
1. Modify `ansible/files/bastion/sshd_config.d/99-cia-hardening.conf` in the repo
2. Commit and push
3. SSH to bastion, copy new file, `sshd -t`, restart ssh
