
output "helix_core_commit_public_ip" {
  description = "Helix Core public IP address"
  value       = var.existing_helix_core ? null : aws_instance.helix_core[0].public_ip
}

output "helix_core_commit_private_ip" {
  description = "Helix Core private IP address"
  value       = var.existing_helix_core ? null : aws_instance.helix_core[0].private_ip
}

output "helix_core_commit_instance_id" {
  description = "Helix Core Instance ID - This is the password for the perforce user"
  value       = var.existing_helix_core ? null : aws_instance.helix_core[0].id
}

output "locust_client_private_ips" {
  description = "Array of private IP addresses for the Locust client EC2 instances"
  value       = aws_instance.locust_clients.*.private_ip
}

output "locust_client_public_ips" {
  description = "Array of public IP addresses for the Locust client EC2 instances"
  value       = aws_instance.locust_clients.*.public_ip
}

output "driver_public_ip" {
  description = "Public IP address of the driver EC2 instance"
  value       = aws_instance.driver.public_ip
}
