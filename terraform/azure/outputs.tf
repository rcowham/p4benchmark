output "locust_client_private_ips" {
  description = "Array of private IP addresses for the Locust client VM instances"
  value       = azurerm_linux_virtual_machine.locustclients.*.private_ip_address
}

output "locust_client_public_ips" {
  description = "Array of public IP addresses for the Locust client VM instances"
  value       = azurerm_linux_virtual_machine.locustclients.*.public_ip_address
}