variable "server_ip" {
  description = "Droplet public IP address"
  type        = string
}

variable "ssh_key_path" {
  description = "Path to local SSH private key"
  type        = string
  default     = "~/.ssh/id_ed25519"  # change to ~/.ssh/id_rsa if needed
}

variable "root_pass" {
  description = "Root user password"
  type        = string
  sensitive   = true
}

variable "db_root_pass" {
  description = "MariaDB root password"
  type        = string
  sensitive   = true
}

variable "deploy_user" {
  description = "Non-root user created for SSH and deployments"
  type        = string
  sensitive   = true
}

variable "ssh_port" {
  description = "SSH port (replaces default 22)"
  type        = number
  sensitive   = true
}
