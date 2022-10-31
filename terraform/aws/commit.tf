
locals {

  helix_core_commit_az = var.existing_vpc ? var.existing_az : module.vpc.azs[0]
  helix_core_subnet_id = var.existing_vpc ? var.existing_public_subnet : module.vpc.public_subnets[0]

  user_data = templatefile("${path.module}/../scripts/userdata.sh", {
    environment          = var.environment
    ssh_public_key       = tls_private_key.ssh-key.public_key_openssh
    ssh_private_key      = tls_private_key.ssh-key.private_key_openssh
    p4benchmark_os_user  = var.p4benchmark_os_user
    s3_checkpoint_bucket = var.s3_checkpoint_bucket
    checkpoint_filename  = var.checkpoint_filename
    archive_filename     = var.archive_filename
  })
}





resource "aws_instance" "helix_core" {
  count = var.existing_helix_core ? 0 : 1

  ami                         = var.ami[var.aws_region]
  instance_type               = var.helix_core_commit_instance_type
  key_name                    = var.key_name
  vpc_security_group_ids      = [module.helix_core_sg.security_group_id]
  subnet_id                   = local.helix_core_subnet_id
  associate_public_ip_address = true
  user_data                   = local.user_data
  monitoring                  = var.monitoring
  private_ip                  = var.private_ip
  iam_instance_profile        = aws_iam_instance_profile.instance.name

  tags = {
    Name = "p4-benchmark-helix-core-commit"
  }
}

# Wait for helix core cloud-init status to complete.  
# This will cause terraform to not create the runner instance until helix core is finished
resource "null_resource" "helix_core_cloud_init_status" {
  count = var.existing_helix_core ? 0 : 1

  connection {
    type = "ssh"
    user = "rocky"
    host = aws_instance.helix_core[0].public_ip
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/cloud_init_status.sh"
    ]
  }
}

resource "aws_volume_attachment" "depot" {
  count = var.existing_helix_core ? 0 : 1

  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.depot[0].id
  instance_id = aws_instance.helix_core[0].id
}

resource "aws_ebs_volume" "depot" {
  count = var.existing_helix_core ? 0 : 1

  availability_zone = local.helix_core_commit_az
  type              = var.depot_volume_type
  size              = var.depot_volume_size
  encrypted         = var.volumes_encrypted
  kms_key_id        = var.volumes_kms_key_id
  iops              = var.depot_volume_iops
  throughput        = var.depot_volume_throughput

  tags = {
    Name = "Helix Core Depot Volume - ${var.environment}"
  }
}

resource "aws_volume_attachment" "log" {
  count = var.existing_helix_core ? 0 : 1

  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.log[0].id
  instance_id = aws_instance.helix_core[0].id
}

resource "aws_ebs_volume" "log" {
  count = var.existing_helix_core ? 0 : 1

  availability_zone = local.helix_core_commit_az
  type              = var.log_volume_type
  size              = var.log_volume_size
  encrypted         = var.volumes_encrypted
  kms_key_id        = var.volumes_kms_key_id
  iops              = var.log_volume_iops
  throughput        = var.log_volume_throughput


  tags = {
    Name = "Helix Core Log Volume - ${var.environment}"
  }
}

resource "aws_volume_attachment" "metadata" {
  count = var.existing_helix_core ? 0 : 1

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.metadata[0].id
  instance_id = aws_instance.helix_core[0].id
}

resource "aws_ebs_volume" "metadata" {
  count = var.existing_helix_core ? 0 : 1

  availability_zone = local.helix_core_commit_az
  type              = var.metadata_volume_type
  size              = var.metadata_volume_size
  encrypted         = var.volumes_encrypted
  kms_key_id        = var.volumes_kms_key_id
  iops              = var.metadata_volume_iops
  throughput        = var.metadata_volume_throughput


  tags = {
    Name = "Helix Core Metadata Volume - ${var.environment}"
  }
}
