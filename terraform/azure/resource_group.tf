# Create a resource group
resource "azurerm_resource_group" "p4benchmark" {
  name     = "p4benchmark-resources"
  location = var.azure_region
  tags = {
    Environment = var.environment
    Owner       = var.owner
    Product     = "Perforce P4 Benchmark"
    Terraform   = "true"
  }
}