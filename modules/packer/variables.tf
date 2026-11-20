variable "deploy_gitlab" {
  type    = bool
  default = false
}

variable "iso_id" { type = string }

variable "packer_directory" {
  type = string
  # default = "/Users/wohshon.phoon/apps/prism/hpoc-prism-setup-scripts/packer-ubuntu-nutanix"
  default = "packer-ubuntu-nutanix"
}

variable "packer_targets" {
  type    = string
  default = "nutanix.ubuntu,nutanix.harbor-registry,nutanix.gitlab"
}

variable "packer_var_file" {
  type    = string
  default = "settings.auto.pkrvars.hcl"
}

variable "bastion_image_name" { type = string }
variable "registry_image_name" { type = string }
variable "gitlab_image_name" { type = string }

variable "bastion_disk_size_gb" {
  type        = number
  description = "Disk size for the Bastion VM in GB"
  default     = 250
}

variable "generic_disk_size_gb" {
  type        = number
  description = "Disk size for the Registry and GitLab VMs in GB"
  default     = 150
}