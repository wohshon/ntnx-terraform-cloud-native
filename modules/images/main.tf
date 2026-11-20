terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
    }
  }
}

resource "nutanix_image" "this" {
  # We loop through a map of images defined in the root
  for_each = var.image_list

  name       = each.key
  source_uri = each.value.source_url
  image_type = each.value.image_type

  project_reference = var.project_id != null ? {
    kind = "project"
    uuid = var.project_id
  } : null

  # This matches your cluster_id logic
  cluster_references {
    kind = "cluster"
    uuid = var.cluster_id
  }
}

# We output the IDs so the VM module knows which 'disk' to use later
output "image_map" {
  value = { for k, v in nutanix_image.this : k => v.id }
}
