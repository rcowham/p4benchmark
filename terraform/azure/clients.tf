
locals {

  client_subnet_id = var.existing_vnet ? data.azurerm_subnet.existing_public_subnet[0].id : azurerm_subnet.vm_p4_subnet[0].id

  client_user_data = base64encode(templatefile("${path.module}/../scripts/client_userdata.sh", {
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

  }))
}

resource "azurerm_linux_virtual_machine" "locustclients" {
  count      = var.client_vm_count
  depends_on = [null_resource.helix_core_cloud_init_status]

  name                = format("p4-benchmark-locust-client-%03d", count.index + 1)
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  size                = var.client_instance_type
  admin_username      = "rocky"
  network_interface_ids = [
    azurerm_network_interface.clients_network_interface[count.index].id,
  ]
  user_data = local.client_user_data

  admin_ssh_key {
    username   = "rocky"
    public_key = data.azurerm_ssh_public_key.rocky-public-key.public_key
  }

  os_disk {
    # Azure by default deletes this disk on deletion (https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/features-block#delete_os_disk_on_deletion)
    caching              = "ReadWrite"
    storage_account_type = var.client_root_volume_type
    disk_size_gb         = var.client_root_volume_size
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

resource "azurerm_public_ip" "clients_public_ip" {
  count               = var.client_vm_count
  name                = format("p4-benchmark-locust-client-publicip-%03d", count.index + 1)
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  allocation_method   = "Dynamic"
  tags                = local.tags
}

resource "azurerm_network_interface" "clients_network_interface" {
  count               = var.client_vm_count
  name                = format("p4-benchmark-locust-client-interface-%03d", count.index + 1)
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.client_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.clients_public_ip[count.index].id
  }
  tags = local.tags
}

# Wait for client cloud-init status to complete.  
# This will cause terraform to not create the driver instance until client is finished
resource "null_resource" "client_cloud_init_status" {
  connection {
    type  = "ssh"
    user  = "rocky"
    host  = azurerm_linux_virtual_machine.locustclients.0.public_ip_address
    agent = true
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/cloud_init_status.sh"
    ]
  }
}
