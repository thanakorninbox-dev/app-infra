variable "server_ip" {
  type = string
}

variable "ssh_key_path" {
  description = "Path to local SSH private key"
  type        = string
  default     = "~/.ssh/id_ed25519"  # change to ~/.ssh/id_rsa if needed
}

variable "db_root_pass" {
  type      = string
  sensitive = true
}

variable "app_name" {
  description = "Nginx site filename and PM2 app identifier"
  type        = string
}

variable "app_path" {
  description = "URL path segment, no slashes (e.g. 'wms-app')"
  type        = string
}

variable "app_base_url" {
  description = "Base URL with slashes (e.g. '/wms-app/')"
  type        = string
}

variable "app_root" {
  description = "Absolute path on server (e.g. '/var/www/html/wms-app')"
  type        = string
}

variable "github_user" {
  type = string
}

variable "github_repo" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "db_name" {
  type = string
}

variable "db_name2" {
  type = string
}

variable "node_port" {
  type    = number
  default = 3000
}

variable "node_emit_secret" {
  type      = string
  sensitive = true
}

variable "deploy_user" {
  description = "Non-root SSH user on the server"
  type        = string
  sensitive   = true
}

variable "ssh_port" {
  description = "SSH port on the server"
  type        = number
  sensitive   = true
}

variable "deploy_version" {
  description = "Bump this value to force a re-deploy"
  type        = string
  default     = "1"
}
