resource "tls_private_key" "ssh-key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "azurerm_ssh_public_key" "rocky-public-key" {
  name                = var.key_name
  resource_group_name = var.key_resource_group_name
}
