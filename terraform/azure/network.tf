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

resource "azurerm_network_security_group" "p4_helix_core_sg" {
  name                = "p4_helix_core_sg"
  resource_group_name = azurerm_resource_group.p4benchmark.name
  location            = azurerm_resource_group.p4benchmark.location
  tags = {
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}

resource "azurerm_network_security_rule" "helix_core_ssh_rule" {
  name                       = "SSH"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "200.80.77.193"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}

resource "azurerm_network_security_rule" "helix_core_https_rule" {
  name                       = "HTTPS"
  priority                   = 200
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "443"
  source_address_prefix      = "200.80.77.193"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}

resource "azurerm_network_security_rule" "helix_core_perforce_rule" {
  name                       = "Perforce"
  priority                   = 300
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "1666"
  source_address_prefix      = "200.80.77.193"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}

resource "azurerm_network_security_rule" "helix_core_hansoft_rule" {
  name                       = "Hansoft"
  priority                   = 500
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "50256"
  source_address_prefix      = "200.80.77.193"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}

resource "azurerm_network_security_rule" "helix_core_http_rule" {
  name                       = "HTTP"
  priority                   = 600
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "80"
  source_address_prefix      = "200.80.77.193"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}

resource "azurerm_network_security_rule" "helix_core_swarm_rule" {
  name                       = "Swarm"
  priority                   = 700
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8443"
  source_address_prefix      = "200.80.77.193"
  destination_address_prefix = "*"
  resource_group_name         = azurerm_resource_group.p4benchmark.name
  network_security_group_name = azurerm_network_security_group.p4_helix_core_sg.name
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.vm_p4_network.id
  network_security_group_id = azurerm_network_security_group.p4_helix_core_sg.id
}