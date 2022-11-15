
locals {

  driver_sg_ids    = var.existing_vpc ? concat(var.existing_sg_ids, [module.driver_sg.security_group_id]) : [module.driver_sg.security_group_id]
  driver_subnet_id = var.existing_vpc ? var.existing_public_subnet : module.vpc[0].public_subnets[0]

  helix_core_commit_username = var.existing_helix_core ? var.existing_helix_core_username : var.helix_core_commit_username
  helix_core_commit_password = var.existing_helix_core ? var.existing_helix_core_password : aws_instance.helix_core[0].id
  helix_core_private_ip      = var.existing_helix_core ? var.existing_helix_core_ip : aws_instance.helix_core[0].private_ip
  helix_core_public_ip       = var.existing_helix_core ? var.existing_helix_core_public_ip : aws_instance.helix_core[0].public_ip

  driver_user_data = templatefile("${path.module}/../scripts/driver_userdata.sh", {
    environment                          = var.environment
    locust_client_ips                    = aws_instance.locust_clients.*.private_ip
    ssh_public_key                       = tls_private_key.ssh-key.public_key_openssh
    ssh_private_key                      = tls_private_key.ssh-key.private_key_openssh
    git_project                          = var.p4benchmark_github_project
    git_branch                           = var.p4benchmark_github_branch
    git_owner                            = var.p4benchmark_github_project_owner
    helix_core_commit_username           = local.helix_core_commit_username
    helix_core_commit_benchmark_username = var.helix_core_commit_benchmark_username
    helix_core_password                  = local.helix_core_commit_password
    helix_core_private_ip                = local.helix_core_private_ip
    number_locust_workers                = var.number_locust_workers
    p4benchmark_os_user                  = var.p4benchmark_os_user
    install_p4prometheus                 = var.install_p4prometheus
    locust_repo_path                     = var.locust_repo_path
    locust_repo_dir_num                  = var.locust_repo_dir_num
    locust_repeat                        = var.locust_repeat
    p4benchmark_dir                      = var.p4benchmark_dir
    locust_workspace_dir                 = var.locust_workspace_dir

  })

  create_files_template = templatefile("${path.module}/../scripts/create_files.sh", {
    helix_core_commit_username           = local.helix_core_commit_username
    helix_core_commit_benchmark_username = var.helix_core_commit_benchmark_username
    helix_core_password                  = local.helix_core_commit_password
    helix_core_private_ip                = local.helix_core_private_ip
  })
}

resource "aws_instance" "driver" {
  depends_on = [null_resource.helix_core_cloud_init_status, null_resource.client_cloud_init_status]

  ami                         = data.aws_ami.rocky.image_id
  instance_type               = var.driver_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = local.driver_sg_ids
  subnet_id                   = local.driver_subnet_id
  associate_public_ip_address = true
  user_data                   = local.driver_user_data
  monitoring                  = var.monitoring
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

resource "null_resource" "upload_create_files" {
  depends_on = [null_resource.driver_cloud_init_status]

  connection {
    type = "ssh"
    user = "rocky"
    host = aws_instance.driver.public_ip
  }

  provisioner "file" {
    content     = local.create_files_template
    destination = "/p4benchmark/createfiles.sh"
  }

  # chmod via remote-exec because the createfiles.sh comes from a template and will not be marked with +x
  provisioner "remote-exec" {
    inline = [
      "chmod +x /p4benchmark/createfiles.sh"
    ]
  }
}

# wait for cloud-init to finish
# the userdata in cloud-init will install createfiles.py and its dependencies
# var.createfiles_configs is a array of maps
# create a new ssh connection to the driver VM for item in the array
# this allows the user to run createfiles N number of times
# the primary use case for this will be:
# create a lot of small files and create a few large files
resource "null_resource" "run_create_files" {
  depends_on = [null_resource.upload_create_files, null_resource.apply_p4d_configurables]
  count      = length(var.createfile_configs)

  connection {
    type = "ssh"
    user = "rocky"
    host = aws_instance.driver.public_ip
  }

  provisioner "remote-exec" {
    inline = [
    "CREATE_FILES_LEVELS='${var.createfile_configs[count.index].createfile_levels}' CREATE_FILES_SIZE='${var.createfile_configs[count.index].createfile_size}' CREATE_FILES_NUMBER='${var.createfile_configs[count.index].createfile_number}' CREATE_FILES_DIRECTORY='${var.createfile_configs[count.index].createfile_directory}' /p4benchmark/createfiles.sh"]
  }
}

resource "null_resource" "apply_p4d_configurables" {
  depends_on = [null_resource.helix_core_cloud_init_status]

  connection {
    type = "ssh"
    user = "rocky"
    host = local.helix_core_public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -i -u perforce p4 configure set net.parallel.max=100",
      "sudo -i -u perforce p4 configure set net.parallel.threads=10",
      "sudo -i -u perforce p4 configure set net.parallel.submit.threads=10"
    ]
  }
}

resource "null_resource" "remove_p4d_configurables" {
  depends_on = [null_resource.run_create_files, null_resource.apply_p4d_configurables]

  connection {
    type = "ssh"
    user = "rocky"
    host = local.helix_core_public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -i -u perforce p4 configure unset net.parallel.max",
      "sudo -i -u perforce p4 configure unset net.parallel.threads",
      "sudo -i -u perforce p4 configure unset net.parallel.submit.threads"
    ]
  }
}
