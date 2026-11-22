variable "bastion_user" {
  type = string
}

variable "nutanix_user" {
  type = string
}

variable "nutanix_password" {
  type      = string
  sensitive = true
}

variable "nutanix_endpoint" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "bastion_ip" {
  type = string
}

variable "registry_ip" {
  type = string
}

variable "gitlab_ip" {
  type = string
}

variable "ad_ip" {
  type = string
}

variable "ad_user" {
  type = string
}

variable "ad_password" {
  type      = string
  sensitive = true
}

variable "bastion_ptr" {
  type = string
}

variable "registry_ptr" {
  type = string
}

variable "gitlab_ptr" {
  type = string
}

# --- SSH Target Machine Variables ---
variable "cvm_ip" {
  type        = string
  description = "IP address of the machine to SSH into (e.g., 10.38.55.37)"
}

variable "cvm_user" {
  type        = string
  description = "SSH Username"
  default     = "nutanix"
}

variable "cvm_password" {
  type        = string
  description = "SSH Password"
  sensitive   = true
}

# --- DHCP Pool Configuration Variables ---
variable "dhcp_network" {
  type        = string
  description = "The target Nutanix network"
  default     = "secondary"
}

variable "dhcp_prefix" {
  type        = string
  description = "The first 3 octets of your network"
  default     = "10.38.55"
}

variable "dhcp_ip0" {
  type        = string
  description = "The last octet for the IP to delete"
}

variable "dhcp_start_ip1" {
  type = string
}

variable "dhcp_end_ip1" {
  type = string
}

variable "dhcp_start_ip2" {
  type = string
}

variable "dhcp_end_ip2" {
  type = string
}

# NKP Pre-req variables
variable "bastion_working_dir" {
  type = string
}
variable "bastion_bundle_name" {
  type = string
}
variable "bastion_bundle_extraction_dir" {
  type = string
}
variable "bastion_installation_scripts_dir" {
  type = string
}
variable "bastion_git_endpoint" {
  type = string
}
variable "bastion_git_branch" {
  type = string
}
variable "nkp_version" {
  type = string
}
variable "nkp_version_major" {
  type = string
}
variable "bastion_env" {
  type = string
}

variable "bastion_bundle_download_url" {
  type = string
}

variable "slack_webhook_url" {
  type = string
}

variable "run_mgmt_script" {
  type        = bool
  description = "Set to true to execute ./mgmt.sh at the end of the provision process."
  default     = false
}

variable "deploy_gitlab" {
  type        = bool
  description = "Set to true to deploy the GitLab VM and build its Packer image."
  default     = false
}

variable "nkp_license_jwt" {
  type        = string
  description = "The JWT license key for the Nutanix Kubernetes Platform"
  sensitive   = true
}

variable "nkp_mgmt_cluster_name" {
  type        = string
  description = "The name of the NKP management cluster"
  default     = "mgmt-cluster-1"
}

variable "nkp_workspace_namespace" {
  type        = string
  description = "The namespace name of the NKP workspace to create"
  default     = "dev-workspace-1234-abcd"
}

variable "nkp_workspace_name" {
  type        = string
  description = "The name of the NKP workspace to create"
  default     = "dev-workspace"
}

variable "ad_bind_password" {
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

variable "private_registry_name" {
  type        = string
  description = "The name of the private registry"
  default     = "registry.ntnxlab.local"
}


# -- AD setup
variable "nkp_ad_groups" {
  description = "Map of AD groups to create, with explicit lists for users and nested groups."
  type = map(object({
    users  = list(string)
    groups = list(string)
  }))
  default = {
    "NKP Admins" = {
      users  = ["Adminuser01", "Adminuser02", "Adminuser03", "Adminuser04", "Adminuser05", "Adminuser06", "Adminuser07", "Adminuser08", "Adminuser09", "Adminuser10"]
      groups = [] # Example: ["SSP Admins"]
    }
    "NKP Users" = {
      users  = ["User01", "User02", "User03", "User04", "User05", "User06", "User07", "User08", "User09", "User10"]
      groups = [] # Example: ["Bootcamp Users"]
    }
    "NKP Devs" = {
      users  = ["Devuser01", "Devuser02", "Devuser03", "Devuser04", "Devuser05", "Devuser06", "Devuser07", "Devuser08", "Devuser09", "Devuser10"]
      groups = [] # Example: ["SSP Developers"]
    }
  }
}

variable "nkp_ubuntu_image_name" {
  type = string
}

variable "nkp_ubuntu_image_download_url" {
  type = string
}

variable "bastion_ubuntu_image_name" {
  type = string
}

variable "bastion_ubuntu_image_download_url" {
  type = string
}

variable "nai_bundle_download_url" {
  type        = string
  description = "HTTP download path for the large NAI airgap bundle"
}

variable "nai_helm_chart_download_url" {
  type        = string
  description = "HTTP download path for the NAI Helm chart"
}

variable "nai_bundle_name" {
  type        = string
  description = "The name of the NAI bundle file"
}
variable "nai_helm_chart_tar" {
  type        = string
  description = "The name of the NAI Helm chart archive"
}

variable "nai_vcpu_count" {
  type        = string
  description = "nai vcpus count"
  default     = "48"
}

variable "nai_memory_size" {
  type        = string
  description = "nai ram size"
  default     = "64"
}

variable "nai_worker_node_count" {
  type        = string
  description = "nai worker nodes replicas count"
  default     = "4"
}

variable "deploy_nai" {
  type        = bool
  description = "Set to true to deploy the NAI background preparation task."
  default     = true
}

variable "project_name" {
  type    = string
  default = null
}

variable "vlan_names" {
  type    = list(string)
  default = ["YOUR_VLAN_1", "YOUR_VLAN_2", "YOUR_VLAN_3"]
}

