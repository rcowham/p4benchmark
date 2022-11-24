resource "azurerm_linux_virtual_machine" "p4_virtual_machine" {
  name                = "p4Benchmark"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  size                = "Standard_DS1_v2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.vm_p4_network.id,
  ]
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "perforce"
    offer = "perforce-helix-core-offer"
    sku = "p4d_2020_1_2107780_v2"
    version = "1.9.5"
  }
  plan {
    name = "p4d_2020_1_2107780_v2"
    publisher = "perforce"
    product = "perforce-helix-core-offer"
  }
  tags = {
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}