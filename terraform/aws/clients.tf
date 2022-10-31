
locals {

  clients_sg_ids   = var.existing_vpc ? concat(var.existing_sg_ids, [module.helix_core_sg.security_group_id]) : [module.helix_core_sg.security_group_id]
  client_subnet_id = var.existing_vpc ? var.existing_public_subnet : module.vpc[0].public_subnets[0]

  client_user_data = templatefile("${path.module}/../scripts/client_userdata.sh", {
    environment         = var.environment
    ssh_public_key      = tls_private_key.ssh-key.public_key_openssh
    ssh_private_key     = tls_private_key.ssh-key.private_key_openssh
    p4benchmark_os_user = var.p4benchmark_os_user

    helix_core_commit_benchmark_username = var.helix_core_commit_benchmark_username
    helix_core_password                  = local.helix_core_commit_password
    helix_core_private_ip                = local.helix_core_private_ip

    git_project = var.p4benchmark_github_project
    git_branch  = var.p4benchmark_github_branch
    git_owner   = var.p4benchmark_github_project_owner

    p4benchmark_dir      = var.p4benchmark_dir
    locust_workspace_dir = var.locust_workspace_dir

  })
}

resource "aws_instance" "locust_clients" {
  count      = var.client_vm_count
  depends_on = [null_resource.helix_core_cloud_init_status]

  ami                         = data.aws_ami.rocky.image_id
  instance_type               = var.client_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = local.clients_sg_ids
  subnet_id                   = local.client_subnet_id
  associate_public_ip_address = true
  user_data                   = local.client_user_data
  monitoring                  = var.monitoring
  iam_instance_profile        = aws_iam_instance_profile.instance.name

  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_size           = var.client_root_volume_size
    volume_type           = var.client_root_volume_type
  }


  tags = {
    Name = "${format("p4-benchmark-locust-client-%03d", count.index + 1)}"
  }
}

# Wait for helix core cloud-init status to complete.  
# This will cause terraform to not create the runner instance until helix core is finished
resource "null_resource" "client_cloud_init_status" {
  connection {
    type = "ssh"
    user = "rocky"
    host = aws_instance.locust_clients.0.public_ip
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/cloud_init_status.sh"
    ]
  }
}


