
locals {

  # clients_sg_ids   = ... # TODO: support NSGs and existing Helix Core deployment
  client_subnet_id = azurerm_subnet.vm_p4_subnet.id # TODO: support existing Helix Core deployment

  client_user_data = base64encode(templatefile("${path.module}/../scripts/client_userdata.sh", {
    environment         = var.environment
    ssh_public_key      = tls_private_key.ssh-key.public_key_openssh
    ssh_private_key     = tls_private_key.ssh-key.private_key_openssh
    p4benchmark_os_user = var.p4benchmark_os_user

    helix_core_commit_benchmark_username = var.helix_core_commit_benchmark_username
    helix_core_password                  = "perforce"  # TODO: local.helix_core_commit_password
    helix_core_private_ip                = "127.0.0.1" # TODO: local.helix_core_private_ip

    git_project = var.p4benchmark_github_project
    git_branch  = var.p4benchmark_github_branch
    git_owner   = var.p4benchmark_github_project_owner

    p4benchmark_dir      = var.p4benchmark_dir
    locust_workspace_dir = var.locust_workspace_dir

  }))
}

resource "azurerm_linux_virtual_machine" "locustclients" {
  count      = var.client_vm_count
  # TODO: enable the following to wait for Helix Core deployment
  # depends_on = [null_resource.helix_core_cloud_init_status]

  name                = format("p4-benchmark-locust-client-%03d", count.index + 1)
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  size                = var.client_instance_type
  admin_username      = "rocky"
  network_interface_ids = [
    azurerm_network_interface.clients_network_interface[count.index].id,
  ]
  user_data                  = local.client_user_data
  encryption_at_host_enabled = true

  admin_ssh_key {
    username   = "rocky"
    public_key = file("~/.ssh/id_rsa.pub") # TODO: grab key from Key Vault
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

  tags = { # TODO: simplify all resources with single tags map object
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}

resource "azurerm_public_ip" "clients_public_ip" {
  count               = var.client_vm_count
  name                = format("p4-benchmark-locust-client-publicip-%03d", count.index + 1)
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  allocation_method   = "Dynamic"

  tags = { # TODO: simplify all resources with single tags map object
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
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

  tags = { # TODO: simplify all resources with single tags map object
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}

# Wait for client cloud-init status to complete.  
# This will cause terraform to not create the driver instance until client is finished
resource "null_resource" "client_cloud_init_status" {
  # TODO: enable the following lines to test whether Client 0 deployment is complete
  # Will be used by driver.tf

  # connection {
  #   type = "ssh"
  #   user = "rocky"
  #   host = azurerm_linux_virtual_machine.locustclients.0.public_ip_address
  # }

  # provisioner "remote-exec" {
  #   scripts = [
  #     "${path.module}/../scripts/cloud_init_status.sh"
  #   ]
  # }
}