terraform {
  required_version = ">= 1.14.0"

  backend "azurerm" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    # AzureRM 4.x enables the managed metrics agent but does not expose the
    # Azure Monitor Workspace association. AzAPI owns that small ARM property.
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}

provider "azapi" {}
