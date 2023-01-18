output "locust_client_private_ips" {
  description = "Array of private IP addresses for the Locust client VM instances"
  value       = azurerm_linux_virtual_machine.locustclients.*.private_ip_address
}

output "locust_client_public_ips" {
  description = "Array of public IP addresses for the Locust client VM instances"
  value       = azurerm_linux_virtual_machine.locustclients.*.public_ip_address
}

output "driver_public_ip" {
  description = "Public IP address of the driver VM instance"
  value       = azurerm_linux_virtual_machine.driver.public_ip_address
}

output "helix_core_commit_public_ip" {
  description = "Helix Core public IP address"
  value       = var.existing_helix_core ? null : azurerm_linux_virtual_machine.helix_core[0].public_ip_address
}

output "helix_core_commit_private_ip" {
  description = "Helix Core private IP address"
  value       = var.existing_helix_core ? null : azurerm_linux_virtual_machine.helix_core[0].private_ip_address
}

output "helix_core_commit_instance_id" {
  description = "Helix Core Instance ID - This is the password for the perforce user"
  value       = var.existing_helix_core ? null : azurerm_linux_virtual_machine.helix_core[0].virtual_machine_id
}
