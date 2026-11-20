resource "terraform_data" "update_dhcp_pools" {
  # If any of these values change in the future, Terraform will re-run the script
  triggers_replace = {
    network = var.dhcp_network
    start1  = var.dhcp_start_ip1
    start2  = var.dhcp_start_ip2
  }

  provisioner "local-exec" {
    command = <<EOT
      ssh-keygen -R ${var.cvm_ip} || true
      sshpass -p '${var.cvm_password}' ssh -o StrictHostKeyChecking=no ${var.cvm_user}@${var.cvm_ip} "bash -l -c '\
        acli net.delete_dhcp_pool ${var.dhcp_network} start=${var.dhcp_prefix}.${var.dhcp_ip0} ; \
        acli net.add_dhcp_pool ${var.dhcp_network} start=${var.dhcp_prefix}.${var.dhcp_start_ip1} end=${var.dhcp_prefix}.${var.dhcp_end_ip1} ; \
        acli net.add_dhcp_pool ${var.dhcp_network} start=${var.dhcp_prefix}.${var.dhcp_start_ip2} end=${var.dhcp_prefix}.${var.dhcp_end_ip2} \
      '"
    EOT
  }
}