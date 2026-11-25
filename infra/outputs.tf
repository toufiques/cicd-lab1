output "storage_account_name" {
  value = azurerm_storage_account.web.name
}

output "site_url" {
  value = azurerm_storage_account.web.primary_web_endpoint
}
