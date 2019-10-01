output "main_endpoint" {
  value = "${azurerm_template_deployment.website.outputs["fqdn"]}"
}