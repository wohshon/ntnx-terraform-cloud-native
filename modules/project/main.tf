terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = ">= 2.5.0"
    }
  }
}

data "nutanix_storage_containers_v2" "all" {}

locals {
  valid_container_ids = [
    for sc in data.nutanix_storage_containers_v2.all.storage_containers : sc.ext_id
    if sc.cluster_ext_id == var.cluster_id
    && !startswith(sc.name, "Nutanix")
    && !startswith(sc.name, "msp-")
    && !startswith(sc.name, "objects")
    && sc.name != "SelfServiceContainer"
  ]
}

resource "nutanix_project_v2" "this" {
  name        = var.project_name
  description = var.project_description
}

resource "nutanix_resource_group_v2" "this" {
  name           = "${var.project_name}-resource-group"
  project_ext_id = nutanix_project_v2.this.ext_id

  placement_targets {
    cluster_ext_id = var.cluster_id

    dynamic "storage_containers" {
      for_each = local.valid_container_ids
      content {
        ext_id = storage_containers.value
      }
    }
  }
}