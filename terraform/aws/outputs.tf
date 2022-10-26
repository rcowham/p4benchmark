
output "helix_core_commit_public_ip" {
  value = aws_instance.helix_core.public_ip
}

output "helix_core_commit_private_ip" {
  value = aws_instance.helix_core.private_ip
}


output "helix_core_commit_instance_id" {
  value = aws_instance.helix_core.id
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "locust_client_private_ips" {
  value = aws_instance.locust_clients.*.private_ip
}

output "locust_client_public_ips" {
  value = aws_instance.locust_clients.*.public_ip
}

output "driver_public_ips" {
  value = aws_instance.driver.public_ip
}
