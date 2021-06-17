variable "PROJECT" {}
variable "ENVIRONMENT" {}

resource "azurerm_resource_group" "rg" {
  name     = var.RESOURCE_GROUP
  location = var.LOCATION
}

resource "random_string" "random" {
  length  = 4
  special = false
  lower   = true
  upper   = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "${var.PROJECT}sa${random_string.random.result}"
  resource_group_name      = var.RESOURCE_GROUP
  location                 = var.LOCATION
  account_tier             = "Standard"
  account_replication_type = "LRS"

  depends_on = [azurerm_resource_group.rg]
}

resource "azurerm_storage_container" "sc" {
  name                  = "${var.PROJECT}-${var.ENVIRONMENT}-sc"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"

  depends_on = [azurerm_resource_group.rg]
}


module "ad" {
  source                    = "./modules/active_directory"
  LOCATION                  = var.LOCATION
  RESOURCE_GROUP            = var.RESOURCE_GROUP
  PROJECT                   = var.PROJECT
  ENVIRONMENT               = var.ENVIRONMENT
  STORAGE_ACC_NAME          = azurerm_storage_account.sa.name
  STORAGE_ACC_KEY           = azurerm_storage_account.sa.primary_access_key
  STORAGE_CONNECTION_STRING = azurerm_storage_account.sa.primary_blob_connection_string

  depends_on = [azurerm_resource_group.rg]
}
