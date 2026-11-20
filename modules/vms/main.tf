terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
      # version = "2.4.0"
    }
  }
}
resource "nutanix_virtual_machine" "this" {
  name         = var.vm_name
  cluster_uuid = var.cluster_id

  project_reference = var.project_id != null ? {
    kind = "project"
    uuid = var.project_id
  } : null

  # Resource sizing matching your Python script
  num_vcpus_per_socket = 1
  num_sockets          = 4
  memory_size_mib      = 8192

  # Power state: This replaces your power_operations("on")
  power_state = "ON"

  # 1. Disk Configuration
  # This clones the image (Packer output or NKP qcow2) onto a SCSI bus
  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = var.image_id
    }
    device_properties {
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
      device_type = "DISK"
    }
  }

  # 2. Networking
  nic_list {
    subnet_uuid = var.subnet_id

    # In some 2.4.0 environments, the field is named exactly like this:
    ip_endpoint_list {
      ip = var.static_ip
    }
  }

  # 3. Cloud-Init (Guest Customization)
  # This matches your GuestCustomizationParams / Userdata logic
  guest_customization_cloud_init_user_data = var.user_data

  # Optional: Adds a description like your Python script did
  description = "Created by Terraform - Nutanix Automation"
  timeouts {
    create = "15m"
  }

  lifecycle {
    ignore_changes = [
      disk_list,
      guest_customization_cloud_init_user_data,
    ]
  }

}