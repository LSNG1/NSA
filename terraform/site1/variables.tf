variable "proxmox_url" {
  description = "URL du Proxmox Site 1"
}

variable "proxmox_user" {
  description = "Utilisateur Proxmox"
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Mot de passe Proxmox"
  sensitive   = true
}

variable "vm_password" {
  description = "Mot de passe des VMs"
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique"
}
