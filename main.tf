terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-storage-secure"
  location = "eastus"
}

resource "azurerm_storage_account" "secure" {
  name                     = "st${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  # Modern security controls (v3.x)
  public_network_access_enabled = false
  shared_access_key_enabled     = false
  allow_nested_items_to_be_public = false

  min_tls_version = "TLS1_2"

  identity {
    type = "SystemAssigned"
  }

  blob_properties {
    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }

    change_feed_enabled = true
    last_access_time_enabled = true
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    ip_rules                   = ["10.0.0.0/24"]
    virtual_network_subnet_ids = [azurerm_subnet.storage_subnet.id]
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-storage"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "storage_subnet" {
  name                 = "snet-storage"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

resource "azurerm_storage_container" "private" {
  name                  = "private-data"
  storage_account_name  = azurerm_storage_account.secure.name
  container_access_type = "private"
}

resource "azurerm_monitor_diagnostic_setting" "diag" {
  name                       = "storage-diag"
  target_resource_id         = azurerm_storage_account.secure.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  log {
    category = "StorageRead"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "StorageWrite"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  log {
    category = "StorageDelete"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 30
    }
  }
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-storage-secure"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}




