locals {

  helix_core_subnet_id = var.existing_vnet ? data.azurerm_subnet.existing_public_subnet[0].id : azurerm_subnet.vm_p4_subnet[0].id

  user_data = base64encode(templatefile("${path.module}/../scripts/helix-core-userdata-azure.sh", {
    environment         = var.environment
    ssh_public_key      = tls_private_key.ssh-key.public_key_openssh
    ssh_private_key     = tls_private_key.ssh-key.private_key_openssh
    p4benchmark_os_user = var.p4benchmark_os_user
    license_filename    = var.license_filename
    blob_account_name   = var.blob_account_name
    blob_container      = var.blob_container
  }))
}

resource "azurerm_linux_virtual_machine" "helix_core" {
  count               = var.existing_helix_core ? 0 : 1
  name                = "p4-benchmark-helix-core"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  size                = var.helix_core_instance_type
  admin_username      = var.helix_core_admin_user
  user_data           = local.user_data
  network_interface_ids = [
    azurerm_network_interface.vm_p4_network[0].id
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
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

# Wait for helix core cloud-init status to complete.  
# This will cause terraform to not create the runner instance until helix core is finished
resource "null_resource" "helix_core_cloud_init_status" {
  count = var.existing_helix_core ? 0 : 1
  connection {
    type  = "ssh"
    user  = var.helix_core_admin_user
    host  = azurerm_linux_virtual_machine.helix_core[0].public_ip_address
    agent = true
  }

  provisioner "remote-exec" {
    scripts = [
      "${path.module}/../scripts/cloud_init_status.sh"
    ]
  }
}

resource "azurerm_managed_disk" "log" {
  count                = var.existing_helix_core ? 0 : 1
  name                 = "helix_core_log"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  location             = azurerm_resource_group.p4benchmark.location
  storage_account_type = var.helix_core_log_volume_type
  create_option        = "Empty"
  disk_size_gb         = var.helix_core_log_volume_size
}

resource "azurerm_managed_disk" "metadata" {
  count                = var.existing_helix_core ? 0 : 1
  name                 = "helix_core_metadata"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  location             = azurerm_resource_group.p4benchmark.location
  storage_account_type = var.helix_core_metadata_volume_type
  create_option        = "Empty"
  disk_size_gb         = var.helix_core_metadata_volume_size
}

resource "azurerm_managed_disk" "depot" {
  count                = var.existing_helix_core ? 0 : 1
  name                 = "helix_core_depot"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  location             = azurerm_resource_group.p4benchmark.location
  storage_account_type = var.helix_core_depot_volume_type
  create_option        = "Empty"
  disk_size_gb         = var.helix_core_depot_volume_size
}

resource "azurerm_virtual_machine_data_disk_attachment" "helix_core_log_disk" {
  count              = var.existing_helix_core ? 0 : 1
  managed_disk_id    = azurerm_managed_disk.log[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.helix_core[0].id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "helix_core_metadata_disk" {
  count = var.existing_helix_core ? 0 : 1
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.helix_core_log_disk[0]
  ]
  managed_disk_id    = azurerm_managed_disk.metadata[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.helix_core[0].id
  lun                = "1"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_machine_data_disk_attachment" "helix_core_depot_disk" {
  count = var.existing_helix_core ? 0 : 1
  depends_on = [
    azurerm_virtual_machine_data_disk_attachment.helix_core_log_disk[0], azurerm_virtual_machine_data_disk_attachment.helix_core_metadata_disk[0]
  ]
  managed_disk_id    = azurerm_managed_disk.depot[0].id
  virtual_machine_id = azurerm_linux_virtual_machine.helix_core[0].id
  lun                = "2"
  caching            = "ReadWrite"
}

resource "azurerm_public_ip" "p4Benchmark_public_ip" {
  count               = var.existing_helix_core ? 0 : 1
  name                = "p4Benchmark_public_ip"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm_p4_network" {
  count               = var.existing_helix_core ? 0 : 1
  name                = "vm_p4_network"
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = local.helix_core_subnet_id
    private_ip_address_allocation = var.helix_coreprivate_ip != "" ? "Static" : "Dynamic"
    private_ip_address            = var.helix_coreprivate_ip
    public_ip_address_id          = azurerm_public_ip.p4Benchmark_public_ip[0].id
  }
  tags = local.tags
}
