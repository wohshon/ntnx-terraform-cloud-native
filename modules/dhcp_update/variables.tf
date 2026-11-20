variable "cvm_ip" { type = string }

variable "cvm_password" {
  type      = string
  sensitive = true
}

variable "cvm_user" { type = string }
variable "dhcp_network" { type = string }
variable "dhcp_prefix" { type = string }
variable "dhcp_ip0" { type = string }
variable "dhcp_start_ip1" { type = string }
variable "dhcp_end_ip1" { type = string }
variable "dhcp_start_ip2" { type = string }
variable "dhcp_end_ip2" { type = string }