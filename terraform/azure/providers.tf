provider "azurerm" {
  features {    
    resource_group {
      prevent_deletion_if_contains_resources = var.prevent_deletion_if_contains_resources
    }
  }
}