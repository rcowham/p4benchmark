data "azurerm_storage_container" "license_container" {
  count                = var.blob_container != "" ? 1 : 0
  name                 = var.blob_container
  storage_account_name = var.blob_account_name
}

resource "azurerm_role_assignment" "storage_read_role" {
  count                = var.blob_container != "" ? 1 : 0
  scope                = data.azurerm_storage_container.license_container[0].resource_manager_id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_linux_virtual_machine.helix_core.identity[0].principal_id
}
