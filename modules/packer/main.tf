terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
    }
  }
}

locals {
  builds = merge(
    {
      bastion  = "nutanix.bastion"
      registry = "nutanix.harbor-registry"
    },
    var.deploy_gitlab ? { gitlab = "nutanix.gitlab" } : {}
  )
}

resource "terraform_data" "packer_init" {
  triggers_replace = {
    variables_sha = filesha256("${var.packer_directory}/variables.pkr.hcl")
  }

  provisioner "local-exec" {
    working_dir = var.packer_directory
    command     = "packer init ."
  }
}

resource "terraform_data" "packer_build" {
  for_each   = local.builds
  depends_on = [terraform_data.packer_init]

  triggers_replace = {
    iso_id    = var.iso_id
    target    = each.value
    disk_size = each.key == "bastion" ? var.bastion_disk_size_gb : var.generic_disk_size_gb
  }

  provisioner "local-exec" {
    working_dir = var.packer_directory
    command     = "packer build -only=${each.value} -var-file=${var.packer_var_file} -var bastion_disk_size_gb=${var.bastion_disk_size_gb} -var generic_disk_size_gb=${var.generic_disk_size_gb} -var source_image=${var.iso_id} ."
  }
}

data "nutanix_images_v2" "bastion_latest" {
  depends_on = [terraform_data.packer_build]

  filter   = "startswith(name,'${var.bastion_image_name}')"
  order_by = "lastUpdateTime desc"
  page     = 0
  limit    = 1
}

data "nutanix_images_v2" "registry_latest" {
  depends_on = [terraform_data.packer_build]

  filter   = "startswith(name,'${var.registry_image_name}')"
  order_by = "lastUpdateTime desc"
  page     = 0
  limit    = 1
}

data "nutanix_images_v2" "gitlab_latest" {
  count      = var.deploy_gitlab ? 1 : 0
  depends_on = [terraform_data.packer_build]

  filter   = "startswith(name,'${var.gitlab_image_name}')"
  order_by = "lastUpdateTime desc"
  page     = 0
  limit    = 1
}

output "bastion_image_id" {
  value = try(data.nutanix_images_v2.bastion_latest.images[0].ext_id, null)
}

output "bastion_image_name" {
  value = try(data.nutanix_images_v2.bastion_latest.images[0].name, null)
}

output "registry_image_id" {
  value = try(data.nutanix_images_v2.registry_latest.images[0].ext_id, null)
}

output "registry_image_name" {
  value = try(data.nutanix_images_v2.registry_latest.images[0].name, null)
}

output "gitlab_image_id" {
  value = try(data.nutanix_images_v2.gitlab_latest[0].images[0].ext_id, null)
}

output "gitlab_image_name" {
  value = try(data.nutanix_images_v2.gitlab_latest[0].images[0].name, null)
}