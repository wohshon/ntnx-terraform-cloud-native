variable "project_name" {
  type = string
}

variable "project_description" {
  type    = string
  default = "Managed by Terraform"
}

variable "cluster_id" {
  type = string
}

variable "ad_password" {
  type      = string
  sensitive = true
}