
terraform {
  required_version = ">= 1.3.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.36.1"
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
