terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Root module should specify the maximum provider version
      # The ~> operator is a convenient shorthand for allowing only patch releases within a specific minor release.
      version = "~> 2.26"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.project}-${var.environment}-register"
  location = var.location
}

resource "azurerm_api_management" "api_management" {
  name                = "test-api-will"
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  publisher_name      = "William Cezar Penna de Oliveira"
  publisher_email     = "williamcezart@gmail.com"
  sku_name            = "Developer_1"
}

resource "azurerm_storage_account" "storage_account" {
  name                     = "${var.project}${var.environment}storage"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_application_insights" "application_insights" {
  name                = "${var.project}-${var.environment}-application-insights"
  location            = var.location
  resource_group_name = azurerm_resource_group.resource_group.name
  application_type    = "Node.JS"
}

resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}-${var.environment}-app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  kind                = "FunctionApp"
  reserved            = true # this has to be set to true for Linux. Not related to the Premium Plan
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "function_app" {
  name                = "${var.project}-${var.environment}-function-app"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = var.location
  app_service_plan_id = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"       = "",
    "FUNCTIONS_WORKER_RUNTIME"       = "node",
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key,
  }
  os_type = "linux"
  site_config {
    linux_fx_version          = "node|14"
    use_32_bit_worker_process = false
  }
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "~3"

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_RUN_FROM_PACKAGE"],
    ]
  }
}

resource "azurerm_api_management_backend" "apim_backend" {
  name                = "example-backend"
  resource_group_name = azurerm_resource_group.resource_group.name
  api_management_name = azurerm_api_management_api.api_management_api.name
  protocol            = "http"
  url                 = "https://${azurerm_function_app.function_app.name}.azurewebsites.net/api/"
}

resource "azurerm_api_management_api" "api_management_api" {
  name                = "example-api"
  resource_group_name = azurerm_resource_group.resource_group.name
  api_management_name = "example-api"
  revision            = "1"
  display_name        = "Example API"
  path                = "test"
  protocols           = ["https"]

  import {
    content_format = "openapi"
    content_value  = file("openApi.yml")
  }
}

resource "azurerm_api_management_api_policy" "example" {
  api_name            = azurerm_api_management_api.api_management_api.name
  api_management_name = azurerm_api_management_api.api_management_api.api_management_name
  resource_group_name = azurerm_api_management_api.api_management_api.resource_group_name

  xml_content = <<XML
    <policies>
      <inbound>
        <base/>
        <set-backend-service backend-id="example-backend" />
      </inbound>
    </policies>
    XML
}
