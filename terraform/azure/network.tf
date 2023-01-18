locals {
  subnets = cidrsubnets(var.vnet_cidr, 4, 4, 4, 4)
}

resource "azurerm_virtual_network" "vm_p4_virtual_network" {
  count               = var.existing_vnet ? 0 : 1
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
  count                = var.existing_vnet ? 0 : 1
  name                 = "public0"
  resource_group_name  = azurerm_resource_group.p4benchmark.name
  virtual_network_name = azurerm_virtual_network.vm_p4_virtual_network[0].name
  address_prefixes     = [local.subnets[0]]
}

resource "azurerm_network_security_group" "p4_helix_core_sg" {
  count               = var.existing_vnet ? 0 : 1
  name                = "p4_helix_core_sg"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  tags                = local.tags
}

resource "azurerm_network_security_rule" "helix_core_ssh_rule" {
  count                       = var.existing_vnet ? 0 : 1
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
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg[0].name
}

resource "azurerm_network_security_rule" "helix_core_perforce_rule" {
  count                       = var.existing_vnet ? 0 : 1
  name                        = "Perforce"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = var.helix_core_port
  source_address_prefixes     = var.ingress_cidrs_1666
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg[0].name
}

resource "azurerm_network_interface_security_group_association" "vnet_sg_association" {
  count                     = var.existing_helix_core ? 0 : 1
  network_interface_id      = azurerm_network_interface.vm_p4_network[0].id
  network_security_group_id = azurerm_network_security_group.p4_helix_core_sg[0].id
}

resource "azurerm_network_security_group" "p4_driver_sg" {
  name                = "p4_driver_sg"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  tags                = local.tags
}

resource "azurerm_network_security_rule" "driver_ssh_rule" {
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
  network_security_group_name = azurerm_network_security_group.p4_driver_sg.name
}

resource "azurerm_network_security_rule" "driver_locust_master_rule" {
  name                        = "locust_master"
  priority                    = 200
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "5557"
  source_address_prefixes     = [var.vnet_cidr]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_driver_sg.name
}

resource "azurerm_network_interface_security_group_association" "vnet_driver_sg_association" {
  network_interface_id      = azurerm_network_interface.driver_network_interface.id
  network_security_group_id = azurerm_network_security_group.p4_driver_sg.id
}


resource "azurerm_network_security_group" "p4_client_sg" {
  name                = "p4_client_sg"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  tags                = local.tags
}

resource "azurerm_network_security_rule" "client_ssh_rule" {
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
  network_security_group_name = azurerm_network_security_group.p4_client_sg.name
}

resource "azurerm_network_interface_security_group_association" "vnet_client_sg_association" {
  count                     = length(azurerm_network_interface.clients_network_interface.*.id)
  network_interface_id      = element(azurerm_network_interface.clients_network_interface.*.id, count.index)
  network_security_group_id = azurerm_network_security_group.p4_client_sg.id
}

data "azurerm_subnet" "existing_public_subnet" {
  count                = var.existing_vnet ? 1 : 0
  name                 = var.existing_subnet_name
  virtual_network_name = var.existing_vnet_name
  resource_group_name  = var.existing_vnet_resource_group
}
