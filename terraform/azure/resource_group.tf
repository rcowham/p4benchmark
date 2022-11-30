# Create a resource group
resource "azurerm_resource_group" "p4benchmark" {
  name     = "p4benchmark-${lower(replace(var.owner, " ", "-"))}"
  location = var.azure_region
  tags = local.tags
}