output "ip_address" {
  description = "The IP address assigned to the VM"
  # This reads the IP back from the NIC configuration of the created VM
  value = nutanix_virtual_machine.this.nic_list[0].ip_endpoint_list[0].ip
}