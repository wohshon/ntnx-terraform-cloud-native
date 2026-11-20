variable "bastion_ip" { type = string }
variable "bastion_user" { type = string }
variable "bastion_working_dir" { type = string }
variable "ad_ip" { type = string }
variable "ad_user" { type = string }

variable "ad_password" {
  type      = string
  sensitive = true
}

variable "nkp_ad_groups" { type = any }