terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.47.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  default_name = "data-factory-cmk-demo"
}

data "azuread_client_config" "this" {} # fpr service principals: azurerm

resource "azurerm_resource_group" "this" {
  location = "westeurope"
  name     = "rg-${local.default_name}"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = "uai-${local.default_name}"
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_key_vault" "this" {
  location            = azurerm_resource_group.this.location
  name                = "kv-${local.default_name}"
  resource_group_name = azurerm_resource_group.this.name
  sku_name            = "standard"
  tenant_id           = data.azuread_client_config.this.tenant_id
  purge_protection_enabled = true
  soft_delete_retention_days = 90
}

resource "azurerm_key_vault_access_policy" "client" {
  key_vault_id = azurerm_key_vault.this.id
  object_id    = data.azuread_client_config.this.object_id
  tenant_id    = data.azuread_client_config.this.tenant_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Update",
    "Delete",
    "Recover",
    "GetRotationPolicy"
  ]
}

resource "azurerm_key_vault_access_policy" "uai" {
  key_vault_id = azurerm_key_vault.this.id
  object_id    = azurerm_user_assigned_identity.this.principal_id
  tenant_id    = data.azuread_client_config.this.tenant_id

  key_permissions = [
    "UnwrapKey",
    "WrapKey",
    "Get"
  ]
}

resource "azurerm_key_vault_key" "this" {
  key_opts     = ["wrapKey", "unwrapKey"]
  key_type     = "RSA"
  key_size     = 4096
  key_vault_id = azurerm_key_vault.this.id
  name         = "customer-managed-key"

  depends_on = [
    azurerm_key_vault_access_policy.client,
    azurerm_key_vault_access_policy.uai
  ]
}

resource "azurerm_data_factory" "this" {
  name                = "df-${local.default_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  github_configuration {
    account_name    = "gersta"
    branch_name     = "main" # collaboration branch
    git_url         = "https://github.com/gersta/azure-data-factory-etl-demo"
    repository_name = "azure-data-factory-etl-demo"
    root_folder     = "/"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.this.id]
  }

  customer_managed_key_id          = azurerm_key_vault_key.this.id
  customer_managed_key_identity_id = azurerm_user_assigned_identity.this.id
}