locals {
  # Render the bash script in memory using the module's variables
  rendered_script = templatefile("${path.module}/nkp_install.sh.tftpl", {
    private_registry_url             = var.private_registry_url
    private_registry_user            = var.private_registry_user
    private_registry_token           = var.private_registry_token
    bastion_ip                       = var.bastion_ip
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
    project_name                     = var.project_name
    ad_bind_password                 = var.ad_bind_password
  })
}

resource "terraform_data" "nkp_full_setup" {
  # Re-run if the script template or any core variables change
  triggers_replace = {
    script_hash = sha256(local.rendered_script)
  }

  provisioner "local-exec" {
    # SSH into the Bastion, launch bash in the background, and pass the rendered script
    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.bastion_user}@${var.bastion_ip} << 'EOF'
nohup bash << 'BACKGROUND_SCRIPT' > /dev/null 2>&1 &
${local.rendered_script}
BACKGROUND_SCRIPT
EOF
EOT
  }
}