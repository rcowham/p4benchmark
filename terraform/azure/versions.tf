
terraform {
  required_version = "1.3.3"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.31.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.2.3"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.1.1"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
  }
}
