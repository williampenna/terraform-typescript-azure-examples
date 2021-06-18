variable "PROJECT" {}
variable "ENVIRONMENT" {}
variable "LOCATION" {}
variable "RESOURCE_GROUP" {}
variable "AD_CLIENT_ID" {}

resource "azurerm_api_management" "apim" {
  name                = "${var.PROJECT}-${var.ENVIRONMENT}-apim"
  location            = var.LOCATION
  resource_group_name = var.RESOURCE_GROUP
  publisher_name      = "William Penna"
  publisher_email     = "williamcezart@gmail.com"

  sku_name = "Developer_1"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_api_management_api" "apimapi" {
  name                = "${var.PROJECT}-${var.ENVIRONMENT}-api"
  resource_group_name = var.RESOURCE_GROUP
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Test API"
  path                = "test_api_management"
  protocols           = ["https"]
  service_url         = "https://${var.PROJECT}-${var.ENVIRONMENT}-fa.azurewebsites.net/api"

  import {
    content_format = "openapi"
    content_value  = file("${path.module}/helloWorld.openapi.yaml")
  }
}

resource "azurerm_api_management_api_policy" "api_management_api_policy_api_public" {
  api_name            = azurerm_api_management_api.apimapi.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = var.RESOURCE_GROUP

  xml_content = <<XML
  <policies>
    <inbound>
      <base />
      <authentication-managed-identity resource="${var.AD_CLIENT_ID}" ignore-error="false" />
    </inbound>
  </policies>
  XML
}
