# Configure the Microsoft Azure Active Directory Provider
variable "PROJECT" {}
variable "ENVIRONMENT" {}
variable "LOCATION" {}
variable "RESOURCE_GROUP" {}
variable "STORAGE_ACC_NAME" {}
variable "STORAGE_ACC_KEY" {}
variable "STORAGE_CONNECTION_STRING" {}

data "azuread_client_config" "current" {}

# Create an application
resource "azuread_application" "aadapp" {
  display_name = "${var.PROJECT}-${var.ENVIRONMENT}-adapp"
}

# Create a service principal
resource "azuread_service_principal" "adsp" {
  application_id = azuread_application.aadapp.application_id
}

module "func" {
  source                    = "../func"
  LOCATION                  = var.LOCATION
  RESOURCE_GROUP            = var.RESOURCE_GROUP
  PROJECT                   = var.PROJECT
  ENVIRONMENT               = var.ENVIRONMENT
  AD_CLIENT_ID              = azuread_application.aadapp.application_id
  TENANT_ID                 = data.azuread_client_config.current.tenant_id
  STORAGE_ACC_NAME          = var.STORAGE_ACC_NAME
  STORAGE_ACC_KEY           = var.STORAGE_ACC_KEY
  STORAGE_CONNECTION_STRING = var.STORAGE_CONNECTION_STRING

  depends_on = [azuread_application.aadapp]
}

resource "local_file" "output" {
  content = jsonencode({
    "app_functions" : {
      "name" : module.func.function_app_name,
      "id" : module.func.function_app_id,
      "hostname" : module.func.function_app_default_hostname,
      "storage_account" : replace(module.func.function_app_storage_connection, "/", "\\/"),
    }
  })
  filename = "../temp_infra/func.json"
}
