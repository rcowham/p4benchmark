
locals {
  driver_user_data = templatefile("${path.module}/../scripts/driver_userdata.sh", {
    environment                          = var.environment
    locust_client_ips                    = aws_instance.locust_clients.*.private_ip
    ssh_public_key                       = tls_private_key.ssh-key.public_key_openssh
    ssh_private_key                      = tls_private_key.ssh-key.private_key_openssh
    git_project                          = var.p4benchmark_github_project
    git_branch                           = var.p4benchmark_github_branch
    git_owner                            = var.p4benchmark_github_project_owner
    createfile_levels                    = var.createfile_levels
    createfile_size                      = var.createfile_size
    createfile_number                    = var.createfile_number
    createfile_directory                 = var.createfile_directory
    helix_core_commit_username           = var.helix_core_commit_username
    helix_core_commit_benchmark_username = var.helix_core_commit_benchmark_username
    helix_core_password                  = aws_instance.helix_core.id
    helix_core_private_ip                = aws_instance.helix_core.private_ip
    number_locust_workers                = var.number_locust_workers
    p4benchmark_os_user                  = var.p4benchmark_os_user
    install_p4prometheus                 = var.install_p4prometheus

  })
}



resource "aws_instance" "driver" {
  depends_on = [null_resource.helix_core_cloud_init_status, null_resource.client_cloud_init_status]

  ami                         = data.aws_ami.rocky.image_id
  instance_type               = var.driver_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [module.driver_sg.security_group_id]
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  user_data                   = local.driver_user_data
  monitoring                  = var.monitoring
  private_ip                  = var.private_ip
  iam_instance_profile        = aws_iam_instance_profile.instance.name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = var.driver_root_volume_size
    volume_type           = var.driver_root_volume_type
  }

  tags = {
    Name = "p4-benchmark-driver"
  }
}

# Wait for cloud-init status to complete.  
resource "null_resource" "driver_cloud_init_status" {
  connection {
    type = "ssh"
    user = "rocky"
    host = aws_instance.driver.public_ip
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/cloud_init_status.sh"
    ]
  }
}
