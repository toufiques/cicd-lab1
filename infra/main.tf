terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Partial backend config: resource group, storage account and container
  # are passed by the pipeline with -backend-config
  backend "azurerm" {
    key              = "lab1.tfstate"
    use_azuread_auth = true
  }
}

provider "azurerm" {
  features {}
  # subscription, tenant, client and OIDC settings come from ARM_* environment variables
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "web" {
  name     = "rg-cicd-lab1-web"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "web" {
  name                     = "stweblab${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.web.name
  location                 = azurerm_resource_group.web.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  tags                     = local.tags
}

resource "azurerm_storage_account_static_website" "web" {
  storage_account_id = azurerm_storage_account.web.id
  index_document     = "index.html"
  error_404_document = "404.html"
}
