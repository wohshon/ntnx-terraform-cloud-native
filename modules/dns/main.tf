terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
      # version = "2.4.0"
    }
  }
}

# 1. Create the hosts file
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/../../ansible/hosts.tftpl", {
    ad_server_ip = var.ad_server_ip
    ad_user      = var.ad_user
    ad_password  = var.ad_password
    bastion_ip   = var.bastion_ip
    registry_ip  = var.registry_ip
    gitlab_ip    = var.gitlab_ip
    bastion_ptr  = var.bastion_ptr
    registry_ptr = var.registry_ptr
    gitlab_ptr   = var.gitlab_ptr
  })
  filename = "${path.module}/../../ansible/hosts"
}

# 2. Run Ansible
resource "terraform_data" "run_ansible" {
  # Trigger when IPs change
  input = {
    bastion  = var.bastion_ip
    registry = var.registry_ip
    gitlab   = var.gitlab_ip
  }

  # CREATE/UPDATE
  provisioner "local-exec" {
    command = "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && ansible-playbook -i ${local_file.ansible_inventory.filename} ${path.module}/../../ansible/playbook.yaml --tags add_bastion_dns,add_registry_dns,add_gitlab_dns"
    # without gitlab
    # command = "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && ansible-playbook -i ${local_file.ansible_inventory.filename} ${path.module}/../../ansible/playbook.yaml --tags add_bastion_dns,add_registry_dns"
  }

  # DELETE (Runs when you destroy the infra)
  provisioner "local-exec" {
    when    = destroy
    command = "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && ansible-playbook -i ${path.module}/../../ansible/hosts ${path.module}/../../ansible/playbook.yaml --tags remove_bastion_dns,remove_registry_dns,remove_gitlab_dns"
    # without gitlab
    # command = "export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES && ansible-playbook -i ${path.module}/../../ansible/hosts ${path.module}/../../ansible/playbook.yaml --tags remove_bastion_dns,remove_registry_dns"
  }
}