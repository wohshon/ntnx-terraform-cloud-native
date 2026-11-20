variable "bastion_ip" { type = string }
variable "bastion_working_dir" { type = string }
variable "slack_webhook_url" { type = string }
variable "cluster_name" { type = string }

variable "nutanix_password" {
  type      = string
  sensitive = true
}

variable "dhcp_prefix" { type = string }
variable "bastion_installation_scripts_dir" { type = string }
variable "bastion_bundle_extraction_dir" { type = string }
variable "bastion_git_endpoint" { type = string }
variable "bastion_git_branch" { type = string }
variable "bastion_env" { type = string }
variable "bastion_bundle_name" { type = string }
variable "bastion_bundle_download_url" { type = string }
variable "nkp_version" { type = string }
variable "nkp_version_major" { type = string }
variable "nkp_mgmt_cluster_name" { type = string }
variable "nkp_ubuntu_image_name" { type = string }
variable "nkp_workspace_namespace" { type = string }
variable "nkp_workspace_name" { type = string }
variable "run_mgmt_script" { type = bool }
variable "bastion_user" { type = string }
variable "nkp_license_jwt" {
  type      = string
  sensitive = true
}

variable "private_registry_user" {
  type        = string
  description = "The username for the private registry"
  default     = "admin"
}

variable "private_registry_token" {
  type        = string
  description = "The token for the private registry"
  sensitive   = true
}


variable "private_registry_url" {
  type        = string
  description = "The URL for the private registry"
  default     = "https://registry.ntnxlab.local"
}
variable "project_name" {
  type    = string
  default = null
}

variable "ad_bind_password" {
  type      = string
  sensitive = true
}