data "nutanix_subnets_v2" "all" {}

locals {
  vlan_map = {
    for s in data.nutanix_subnets_v2.all.subnets : s.name => s
    if contains(var.vlan_names, s.name)
  }
}

import {
  for_each = local.vlan_map
  to       = nutanix_subnet_v2.vlans[each.key]
  id       = each.value.ext_id
}

resource "nutanix_subnet_v2" "vlans" {
  for_each = local.vlan_map

  name              = each.value.name
  subnet_type       = each.value.subnet_type
  network_id        = each.value.network_id
  cluster_reference = each.value.cluster_reference

  shared_with_projects = [module.project.project_id]

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      ip_config,
      dhcp_options,
      virtual_switch_reference,
      vpc_reference,
      description,
      is_advanced_networking,
      is_external,
      is_nat_enabled,
      is_connected,
      bridge_name,
      hypervisor_type,
      reserved_ip_addresses,
    ]
  }
}