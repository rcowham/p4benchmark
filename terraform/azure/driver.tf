
locals {

  driver_subnet_id = var.existing_vnet ? data.azurerm_subnet.existing_public_subnet[0].id : azurerm_subnet.vm_p4_subnet[0].id

  helix_core_commit_username = var.existing_helix_core ? var.existing_helix_core_username : var.helix_core_commit_username
  helix_core_commit_password = var.existing_helix_core ? var.existing_helix_core_password : azurerm_linux_virtual_machine.helix_core[0].virtual_machine_id
  helix_core_private_ip      = var.existing_helix_core ? var.existing_helix_core_ip : azurerm_linux_virtual_machine.helix_core[0].private_ip_address
  helix_core_public_ip       = var.existing_helix_core ? var.existing_helix_core_public_ip : azurerm_linux_virtual_machine.helix_core[0].public_ip_address

  driver_user_data = base64encode(templatefile("${path.module}/../scripts/driver_userdata.sh", {
    environment                          = var.environment
    locust_client_ips                    = azurerm_linux_virtual_machine.locustclients.*.private_ip_address
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

  }))

  create_files_template = templatefile("${path.module}/../scripts/create_files.sh", {
    helix_core_commit_username           = local.helix_core_commit_username
    helix_core_commit_benchmark_username = var.helix_core_commit_benchmark_username
    helix_core_password                  = local.helix_core_commit_password
    helix_core_private_ip                = local.helix_core_private_ip
  })
}

resource "azurerm_linux_virtual_machine" "driver" {
  name                  = "p4-benchmark-driver"
  depends_on            = [null_resource.helix_core_cloud_init_status, null_resource.client_cloud_init_status]
  resource_group_name   = azurerm_resource_group.p4benchmark.name
  location              = azurerm_resource_group.p4benchmark.location
  size                  = var.driver_instance_type
  admin_username        = "rocky"
  network_interface_ids = [azurerm_network_interface.driver_network_interface.id]
  user_data             = local.driver_user_data
  # TODO monitoring, IAM

  admin_ssh_key {
    username   = "rocky"
    public_key = data.azurerm_ssh_public_key.rocky-public-key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.driver_root_volume_type
    disk_size_gb         = var.driver_root_volume_size
  }

  source_image_reference {
    publisher = "perforce"
    offer     = "rockylinux8"
    sku       = "8-gen2"
    version   = "8.6.2022060701"
  }

  plan {
    name      = "8-gen2"
    publisher = "perforce"
    product   = "rockylinux8"
  }

  tags = local.tags
}

resource "azurerm_public_ip" "driver_public_ip" {
  name                = "p4-benchmark-driver-publicip"
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  allocation_method   = "Dynamic"

  tags = local.tags
}

resource "azurerm_network_interface" "driver_network_interface" {
  name                = "p4-benchmark-driver-interface"
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.driver_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.driver_public_ip.id
  }

  tags = local.tags
}

# Wait for cloud-init status to complete.
resource "null_resource" "driver_cloud_init_status" {
  connection {
    type  = "ssh"
    user  = "rocky"
    host  = azurerm_linux_virtual_machine.driver.public_ip_address
    agent = true
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
    type  = "ssh"
    user  = "rocky"
    host  = azurerm_linux_virtual_machine.driver.public_ip_address
    agent = true
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
    type  = "ssh"
    user  = "rocky"
    host  = azurerm_linux_virtual_machine.driver.public_ip_address
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
    "CREATE_FILES_LEVELS='${var.createfile_configs[count.index].createfile_levels}' CREATE_FILES_SIZE='${var.createfile_configs[count.index].createfile_size}' CREATE_FILES_NUMBER='${var.createfile_configs[count.index].createfile_number}' CREATE_FILES_DIRECTORY='${var.createfile_configs[count.index].createfile_directory}' /p4benchmark/createfiles.sh"]
  }
}

resource "null_resource" "apply_p4d_configurables" {
  depends_on = [null_resource.helix_core_cloud_init_status]

  connection {
    type  = "ssh"
    user  = "rocky"
    host  = local.helix_core_public_ip
    agent = true
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
    type  = "ssh"
    user  = "rocky"
    host  = local.helix_core_public_ip
    agent = true
  }

  provisioner "remote-exec" {
    inline = [
      "sudo -i -u perforce p4 configure unset net.parallel.max",
      "sudo -i -u perforce p4 configure unset net.parallel.threads",
      "sudo -i -u perforce p4 configure unset net.parallel.submit.threads"
    ]
  }
}
