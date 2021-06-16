### INPUT VARs ###
variable "PROJECT" {}
variable "ENVIRONMENT" {}
variable "LOCATION" {}
variable "RESOURCE_GROUP" {}
variable "STORAGE_ACC_NAME" {}
variable "STORAGE_ACC_KEY" {}
variable "STORAGE_CONNECTION_STRING" {}

resource "azurerm_application_insights" "ai" {
  name                = "${var.PROJECT}-${var.ENVIRONMENT}-ai"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  application_type    = "Node.JS"
}

resource "azurerm_app_service_plan" "asp" {
  name                = "${var.PROJECT}-${var.ENVIRONMENT}-asp"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  kind                = "FunctionApp"
  reserved = true
  sku {
    tier = "Dynamic"
    size = "Y1"
  }

}

resource "azurerm_function_app" "fa" {
  name                = "${var.PROJECT}-${var.ENVIRONMENT}-fa"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  app_service_plan_id = azurerm_app_service_plan.asp.id
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "node",
    AzureWebJobsStorage = var.STORAGE_CONNECTION_STRING,
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.ai.instrumentation_key,
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }

  os_type                    = "linux"
  storage_account_name       = var.STORAGE_ACC_NAME
  storage_account_access_key = var.STORAGE_ACC_KEY
  version                    = "~3"

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }

  # FIXME: Use DNS names instead of enabling CORS
  site_config {
    cors {
      allowed_origins = ["*"]
    }
  }
}

module "apim" {
  source                    = "../api_management"
  LOCATION                  = var.LOCATION
  RESOURCE_GROUP            = var.RESOURCE_GROUP
  PROJECT                   = var.PROJECT
  ENVIRONMENT               = var.ENVIRONMENT

  depends_on = [azurerm_function_app.fa]
}