# Create a resource group
resource "azurerm_resource_group" "p4benchmark" {
  name     = "p4benchmark-resources"
  location = var.azure_region
  tags = local.tags
}