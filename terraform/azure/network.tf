locals {
  subnets = cidrsubnets(var.vnet_cidr, 4, 4, 4, 4)
}

resource "azurerm_virtual_network" "vm_p4_virtual_network" {
  name                = "p4benchmark"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.p4benchmark.location
  resource_group_name = azurerm_resource_group.p4benchmark.name
  tags                = local.tags
}


# CIDR blocks for rest of subnets if we need them:
##  private_subnets = [local.subnets[2], local.subnets[3]]
##  public_subnets  = [local.subnets[0], local.subnets[1]]
resource "azurerm_subnet" "vm_p4_subnet" {
  name                 = "public0"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  virtual_network_name = azurerm_virtual_network.vm_p4_virtual_network.name
  address_prefixes     = [local.subnets[0]]
}

resource "azurerm_network_security_group" "p4_helix_core_sg" {
  name                = "p4_helix_core_sg"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  tags                = local.tags
}

resource "azurerm_network_security_rule" "helix_core_ssh_rule" {
  name                        = "SSH"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.ingress_cidrs_22
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}

resource "azurerm_network_security_rule" "helix_core_perforce_rule" {
  name                        = "Perforce"
  priority                    = 300
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1666"
  source_address_prefixes     = var.ingress_cidrs_1666
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}


resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.vm_p4_network.id
  network_security_group_id = azurerm_network_security_group.p4_helix_core_sg.id
}
