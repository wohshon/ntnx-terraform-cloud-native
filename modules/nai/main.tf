resource "null_resource" "nai_async_prep" {
  depends_on = []

  provisioner "local-exec" {
    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.bastion_user}@${var.bastion_ip} << 'EOF'
nohup bash << 'BACKGROUND_NAI_PREP' > /dev/null 2>&1 &
${templatefile("${path.module}/nai_prep.sh.tftpl", {
    bastion_working_dir              = var.bastion_working_dir
    slack_webhook_url                = var.slack_webhook_url
    bastion_ip                       = var.bastion_ip
    cluster_name                     = var.cluster_name
    bastion_installation_scripts_dir = var.bastion_installation_scripts_dir
    bastion_env                      = var.bastion_env
    nai_helm_chart_download_url      = var.nai_helm_chart_download_url
    nai_bundle_download_url          = var.nai_bundle_download_url
    dhcp_prefix                      = var.dhcp_prefix
    nkp_mgmt_cluster_name            = var.nkp_mgmt_cluster_name
    nkp_workspace_name               = var.nkp_workspace_name
    nkp_workspace_namespace          = var.nkp_workspace_namespace
    private_registry_url             = var.private_registry_url
    private_registry_name            = var.private_registry_name
    private_registry_user            = var.private_registry_user
    private_registry_token           = var.private_registry_token
    nai_bundle_name                  = var.nai_bundle_name
    nai_helm_chart_tar               = var.nai_helm_chart_tar
    nai_worker_node_count            = var.nai_worker_node_count
    nai_vcpu_count                   = var.nai_vcpu_count
    nai_memory_size                  = var.nai_memory_size
})}
BACKGROUND_NAI_PREP
EOF
EOT
}
}