output "function_app_name" {
  value = azurerm_function_app.function_app.name
  description = "Deployed function app name"
}

output "function_app_default_hostname" {
  value = azurerm_function_app.function_app.default_hostname
  description = "Deployed function app hostname"
}

output "api_management" {
  value = azurerm_api_management.api_management.name
  description = "Deployed API Management name"
}