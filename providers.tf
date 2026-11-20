terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "2.5.1"
    }
  }
}

provider "nutanix" {
  username     = var.nutanix_user
  password     = var.nutanix_password
  endpoint     = var.nutanix_endpoint
  port         = 9440
  insecure     = true
  wait_timeout = 60
}