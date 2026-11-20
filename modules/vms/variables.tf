variable "vm_name" {
  type = string
}

variable "cluster_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "image_id" {
  type = string
}

variable "static_ip" {
  type = string
}

variable "user_data" {
  type        = string
  description = "Base64 encoded cloud-init data"
}
variable "project_id" {
  type    = string
  default = null
}