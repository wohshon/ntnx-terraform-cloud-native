variable "bastion_ip" {
  type        = string
  description = "IP address of the Bastion VM"
}

variable "bastion_user" {
  type        = string
  default     = "wohshon"
  description = "SSH user for the Bastion VM"
}

variable "bastion_working_dir" {
  type        = string
  description = "Base working directory on the Bastion VM"
}

variable "bastion_installation_scripts_dir" {
  type        = string
  description = "Directory where the git repository was cloned"
}

variable "nai_bundle_download_url" {
  type        = string
  description = "URL to fetch the 65GB NAI bundle"
}

variable "nai_helm_chart_download_url" {
  type        = string
  description = "URL to fetch the NAI Helm chart"
}

variable "slack_webhook_url" {
  type        = string
  description = "Slack Webhook URL for process status alerts"
}

variable "cluster_name" {
  type        = string
  description = "Nutanix PE Cluster name for Slack notifications"
}
variable "bastion_env" {
  type        = string
  description = "Environment directory (e.g. hpoc)"
}

variable "dhcp_prefix" {
  type        = string
  description = "The first 3 octets of your network"
}
variable "nkp_mgmt_cluster_name" {
  type        = string
  description = "The name of the NKP management cluster"
  default     = "mgmt-cluster-1"
}
variable "nkp_workspace_name" {
  type = string
}

variable "nkp_workspace_namespace" {
  type = string
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

variable "private_registry_name" {
  type        = string
  description = "The registry name for the private registry"
  default     = "registry.ntnxlab.local"
}

variable "private_registry_url" {
  type        = string
  description = "The URL for the private registry"
  default     = "https://registry.ntnxlab.local"
}

variable "nai_bundle_name" {
  type        = string
  description = "The name of the NAI bundle file"
}
variable "nai_helm_chart_tar" {
  type        = string
  description = "The name of the NAI Helm chart archive"
}