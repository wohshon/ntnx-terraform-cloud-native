variable "cluster_id" {
  type        = string
  description = "The UUID of the Nutanix cluster"
}

variable "image_list" {
  type = map(object({
    source_url = string
    image_type = string
  }))
  description = "Map of image names to their URLs and types (ISO_IMAGE or DISK_IMAGE)"
}

variable "project_name" {
  type    = string
  default = null
}

variable "project_id" {
  type    = string
  default = null
}