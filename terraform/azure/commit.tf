locals {

  user_data = base64encode(templatefile("${path.module}/../scripts/helix-core-userdata-azure.sh", {
    environment         = var.environment
    ssh_public_key      = tls_private_key.ssh-key.public_key_openssh
    ssh_private_key     = tls_private_key.ssh-key.private_key_openssh
    p4benchmark_os_user = var.p4benchmark_os_user
  }))
}

resource "azurerm_linux_virtual_machine" "helix_core" {
  name                = "p4-benchmark-helix-core"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  size                = var.helix_core_instance_type
  admin_username      = var.helix_core_admin_user
  user_data           = local.user_data
  network_interface_ids = [
    azurerm_network_interface.vm_p4_network.id,
  ]
  admin_ssh_key {
    username   = var.helix_core_admin_user
    public_key = data.azurerm_ssh_public_key.rocky-public-key.public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.helix_core_root_volume_type
    disk_size_gb         = var.helix_core_root_volume_size
  }
  source_image_reference {
    publisher = "perforce"
    offer     = "perforce-helix-core-offer"
    sku       = "p4d_2020_1_2107780_v2"
    version   = "1.9.5"
  }
  plan {
    name      = "p4d_2020_1_2107780_v2"
    publisher = "perforce"
    product   = "perforce-helix-core-offer"
  }
  tags = local.tags
}

# Wait for helix core cloud-init status to complete.  
# This will cause terraform to not create the runner instance until helix core is finished
resource "null_resource" "helix_core_cloud_init_status" {
  connection {
    type        = "ssh"
    user        = var.helix_core_admin_user
    host        = azurerm_linux_virtual_machine.helix_core.public_ip_address
    agent = true
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/cloud_init_status.sh"
    ]
  }
}

resource "azurerm_managed_disk" "log" {
  name                 = "helix_core_log"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  location             = azurerm_resource_group.p4benchmark.location
  storage_account_type = var.helix_core_log_volume_type
  create_option        = "Empty"
  disk_size_gb         = var.helix_core_log_volume_size
}

resource "azurerm_managed_disk" "metadata" {
  name                 = "helix_core_metadata"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  location             = azurerm_resource_group.p4benchmark.location
  storage_account_type = var.helix_core_metadata_volume_type
  create_option        = "Empty"
  disk_size_gb         = var.helix_core_metadata_volume_size
}

resource "azurerm_managed_disk" "depot" {
  name                 = "helix_core_depot"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  location             = azurerm_resource_group.p4benchmark.location
  storage_account_type = var.helix_core_depot_volume_type
  create_option        = "Empty"
  disk_size_gb         = var.helix_core_depot_volume_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "helix_core_log_disk" {
  managed_disk_id    = azurerm_managed_disk.log.id
  virtual_machine_id = azurerm_linux_virtual_machine.helix_core.id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "helix_core_metadata_disk" {
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.helix_core_log_disk
  ]
  managed_disk_id    = azurerm_managed_disk.metadata.id
  virtual_machine_id = azurerm_linux_virtual_machine.helix_core.id
  lun                = "1"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "helix_core_depot_disk" {
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.helix_core_log_disk, azurerm_virtual_machine_data_disk_attachment.helix_core_metadata_disk
  ]
  managed_disk_id    = azurerm_managed_disk.depot.id
  virtual_machine_id = azurerm_linux_virtual_machine.helix_core.id
  lun                = "2"
  caching            = "ReadWrite"
}

resource "azurerm_public_ip" "p4Benchmark_public_ip" {
  name                = "p4Benchmark_public_ip"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  allocation_method   = "Static"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm_p4_network" {
  name                = "vm_p4_network"
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_p4_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.p4Benchmark_public_ip.id
  }
  tags = local.tags
}
