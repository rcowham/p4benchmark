resource "azurerm_virtual_network" "vm_p4_virtual_network" {
  name                = "vm_p4_virtual_network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  tags = {
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}

resource "azurerm_subnet" "vm_p4_subnet" {
  name                 = "vm_p4_subnet"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  virtual_network_name = azurerm_virtual_network.vm_p4_virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "vm_p4_network" {
  name                = "vm_p4_network"
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_p4_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = {
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}