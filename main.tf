# --- DATA LOOKUPS ---
# These are required so the modules can find the Cluster and Subnet IDs
data "nutanix_cluster" "target_cluster" {
  name = var.cluster_name
}

data "nutanix_subnet" "primary" {
  subnet_name = var.subnet_name
}


# ######################### MODULES #########################
module "project" {
  source       = "./modules/project"
  project_name = var.project_name
  cluster_id   = data.nutanix_cluster.target_cluster.id
  ad_password  = var.ad_password
}

# 1. Image Uploads
module "nutanix_images" {
  source     = "./modules/images"
  cluster_id = data.nutanix_cluster.target_cluster.id
  # set to null to use the default project _internal
  # looks like it does not affect visibility in other projects
  # project_id = module.project.project_id
  project_id = null

  image_list = {
    "${var.bastion_ubuntu_image_name}" = {
      source_url = "${var.bastion_ubuntu_image_download_url}"
      image_type = "ISO_IMAGE"
    },
    "${var.nkp_ubuntu_image_name}" = {
      source_url = "${var.nkp_ubuntu_image_download_url}"
      image_type = "DISK_IMAGE"
    }
  }
}

# 2. Call packer files to prepare VMs images
# 2. Packer Build (Triggered by the ISO)
# you should have installed the plugin or update regularly
# /usr/bin/packer plugins install github.com/nutanix-cloud-native/nutanix
module "packer_build" {
  source = "./modules/packer"

  iso_id              = module.nutanix_images.image_map["${var.bastion_ubuntu_image_name}"]
  bastion_image_name  = "bastion-host-prod-"
  registry_image_name = "harbor-registry-prod-"
  gitlab_image_name   = "gitlab-prod-"
  deploy_gitlab       = var.deploy_gitlab

  # Pass the disk sizes into the module
  bastion_disk_size_gb = 500
  generic_disk_size_gb = 150
}

# 3. Bastion VM
module "bastion_vm" {
  source     = "./modules/vms"
  vm_name    = "bastion"
  cluster_id = data.nutanix_cluster.target_cluster.id
  subnet_id  = data.nutanix_subnet.primary.id
  image_id   = module.packer_build.bastion_image_id
  static_ip  = var.bastion_ip
  user_data  = filebase64("${path.cwd}/userdata.yaml")
  # project_id = module.project.project_id
  # we need to keep this out of the custom project else it cannot be unshared from the custom project
  project_id = null
}

# 4. Registry VM
module "registry_vm" {
  source     = "./modules/vms"
  vm_name    = "registry"
  cluster_id = data.nutanix_cluster.target_cluster.id
  subnet_id  = data.nutanix_subnet.primary.id
  image_id   = module.packer_build.registry_image_id
  static_ip  = var.registry_ip
  user_data  = filebase64("${path.cwd}/userdata.yaml")
  # project_id = module.project.project_id
  # we need to keep this out of the custom project else it cannot be unshared from the custom project
  project_id = null
}


module "gitlab_vm" {
  source = "./modules/vms"
  count  = var.deploy_gitlab ? 1 : 0

  vm_name    = "gitlab"
  cluster_id = data.nutanix_cluster.target_cluster.id
  subnet_id  = data.nutanix_subnet.primary.id
  image_id   = module.packer_build.gitlab_image_id
  static_ip  = var.gitlab_ip
  user_data  = filebase64("${path.cwd}/userdata.yaml")
  # project_id = module.project.project_id
  # we need to keep this out of the custom project else it cannot be unshared from the custom project
  project_id = null
}

module "dns_update" {
  source = "./modules/dns"

  # Active Directory Credentials
  ad_server_ip = var.ad_ip
  ad_user      = var.ad_user
  ad_password  = var.ad_password

  bastion_ip  = var.bastion_ip
  registry_ip = var.registry_ip
  gitlab_ip   = var.gitlab_ip

  # PTR record prefixes
  bastion_ptr  = var.bastion_ptr
  registry_ptr = var.registry_ptr
  gitlab_ptr   = var.gitlab_ptr

  depends_on = [
    module.bastion_vm,
    module.registry_vm
  ]
}


# --- POST-DEPLOYMENT SCRIPTS ---
module "dhcp_update" {
  source = "./modules/dhcp_update"

  # Pass all required variables
  cvm_ip         = var.cvm_ip
  cvm_password   = var.cvm_password
  cvm_user       = var.cvm_user
  dhcp_network   = var.dhcp_network
  dhcp_prefix    = var.dhcp_prefix
  dhcp_ip0       = var.dhcp_ip0
  dhcp_start_ip1 = var.dhcp_start_ip1
  dhcp_end_ip1   = var.dhcp_end_ip1
  dhcp_start_ip2 = var.dhcp_start_ip2
  dhcp_end_ip2   = var.dhcp_end_ip2

  # The dependencies are declared on the module block itself
  depends_on = [
    module.dns_update,
    module.bastion_vm
  ]
}


module "nkp_setup" {
  source = "./modules/nkp_setup"

  depends_on = [
    module.dns_update,
    module.bastion_vm,
    module.registry_vm,
    module.dhcp_update,
    module.bastion_ad_config
  ]

  bastion_ip                       = var.bastion_ip
  bastion_user                     = var.bastion_user
  bastion_working_dir              = var.bastion_working_dir
  slack_webhook_url                = var.slack_webhook_url
  cluster_name                     = var.cluster_name
  nutanix_password                 = var.nutanix_password
  dhcp_prefix                      = var.dhcp_prefix
  bastion_installation_scripts_dir = var.bastion_installation_scripts_dir
  bastion_bundle_extraction_dir    = var.bastion_bundle_extraction_dir
  bastion_git_endpoint             = var.bastion_git_endpoint
  bastion_git_branch               = var.bastion_git_branch
  bastion_env                      = var.bastion_env
  bastion_bundle_name              = var.bastion_bundle_name
  bastion_bundle_download_url      = var.bastion_bundle_download_url
  nkp_version                      = var.nkp_version
  nkp_version_major                = var.nkp_version_major
  nkp_mgmt_cluster_name            = var.nkp_mgmt_cluster_name
  nkp_ubuntu_image_name            = var.nkp_ubuntu_image_name
  nkp_workspace_namespace          = var.nkp_workspace_namespace
  nkp_workspace_name               = var.nkp_workspace_name
  run_mgmt_script                  = var.run_mgmt_script
  nkp_license_jwt                  = var.nkp_license_jwt
  private_registry_url             = var.private_registry_url
  private_registry_user            = var.private_registry_user
  private_registry_token           = var.private_registry_token
  project_name                     = var.project_name
  ad_bind_password                 = var.ad_bind_password

}


module "bastion_ad_config" {
  source = "./modules/ad_config"

  depends_on = [
    module.bastion_vm
  ]

  bastion_ip          = var.bastion_ip
  bastion_user        = var.bastion_user
  bastion_working_dir = var.bastion_working_dir
  ad_ip               = var.ad_ip
  ad_user             = var.ad_user
  ad_password         = var.ad_password
  nkp_ad_groups       = var.nkp_ad_groups
}

# --- NUTANIX ENTERPRISE AI (NAI) PREPARATION ---
# terraform apply -replace="module.nai_setup[0].null_resource.nai_async_prep"
module "nai_setup" {
  count  = var.deploy_nai ? 1 : 0
  source = "./modules/nai"

  bastion_user                     = var.bastion_user
  bastion_env                      = var.bastion_env
  bastion_ip                       = var.bastion_ip
  bastion_working_dir              = var.bastion_working_dir
  bastion_installation_scripts_dir = var.bastion_installation_scripts_dir
  dhcp_prefix                      = var.dhcp_prefix
  nai_bundle_name                  = var.nai_bundle_name
  nai_helm_chart_tar               = var.nai_helm_chart_tar
  nai_bundle_download_url          = var.nai_bundle_download_url
  nai_helm_chart_download_url      = var.nai_helm_chart_download_url
  nkp_mgmt_cluster_name            = var.nkp_mgmt_cluster_name
  nkp_workspace_name               = var.nkp_workspace_name
  nkp_workspace_namespace          = var.nkp_workspace_namespace
  slack_webhook_url                = var.slack_webhook_url
  cluster_name                     = var.cluster_name
  private_registry_name            = var.private_registry_name
  private_registry_user            = var.private_registry_user
  private_registry_token           = var.private_registry_token
  nai_worker_node_count            = var.nai_worker_node_count
  nai_vcpu_count                   = var.nai_vcpu_count
  nai_memory_size                  = var.nai_memory_size

  depends_on = [
    module.bastion_vm,
    module.registry_vm,
    module.dns_update
  ]
}