resource "terraform_data" "bastion_ad_config" {
  provisioner "local-exec" {
    command = <<EOT
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${var.bastion_user}@${var.bastion_ip} << 'EOF'
set -e

echo "Installing Ansible and WinRM dependencies..."
sudo apt-get update > /dev/null 2>&1
sudo apt-get install -y ansible python3-winrm > /dev/null 2>&1

echo "Installing microsoft.ad collection..."
ansible-galaxy collection install ansible.windows microsoft.ad > /dev/null 2>&1

echo "Generating Ansible Inventory..."
cat << 'INVENTORY' > ${var.bastion_working_dir}/ad_inventory.ini
[domain_controllers]
${var.ad_ip}

[domain_controllers:vars]
ansible_user=${var.ad_user}
ansible_password=${var.ad_password}
ansible_connection=winrm
ansible_port=5985
ansible_winrm_scheme=http
ansible_winrm_server_cert_validation=ignore
ansible_winrm_transport=ntlm
INVENTORY

echo "Generating dynamic vars file from Terraform map..."
cat << 'VARS_YML' > ${var.bastion_working_dir}/ad_vars.yml
${yamlencode({
    ad_groups = {
      for group_name, config in var.nkp_ad_groups :
      group_name => concat(coalesce(config.users, []), coalesce(config.groups, []))
    }
})}
VARS_YML

echo "Generating Ansible Playbook..."
cat << 'PLAYBOOK' > ${var.bastion_working_dir}/ad_config.yml
---
- name: Configure AD Users and Groups
  hosts: domain_controllers
  gather_facts: no
  vars_files:
    - ad_vars.yml
  tasks:
    - name: Create nkp-svc user and add to Administrators
      microsoft.ad.user:
        name: nkp-svc
        password: "Passw0rd1234_"
        state: present
        groups:
          add:
            - Administrators
        password_never_expires: yes
        user_cannot_change_password: yes

    - name: Create AD groups dynamically
      microsoft.ad.group:
        name: "{{ item.key }}"
        scope: global
        state: present
      loop: "{{ ad_groups | dict2items }}"

    - name: Add members to AD groups dynamically
      microsoft.ad.group:
        name: "{{ item.key }}"
        members:
          add: "{{ item.value }}"
      loop: "{{ ad_groups | dict2items }}"
      when: item.value | length > 0
PLAYBOOK

echo "Running Ansible Playbook from Bastion to configure Active Directory..."
ansible-playbook -i ${var.bastion_working_dir}/ad_inventory.ini ${var.bastion_working_dir}/ad_config.yml

echo "Active Directory configuration complete!"
EOF
EOT
}
}