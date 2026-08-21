output "application_gateway_public_ip" {
  value = azurerm_public_ip.agw_public_ip.ip_address
}

output "vm1_private_ip" {
  value = azurerm_network_interface.vm1_nic.private_ip_address
}

output "vm2_private_ip" {
  value = azurerm_network_interface.vm2_nic.private_ip_address
}

output "vm2_public_ip" {
  value = azurerm_public_ip.vm2_public_ip.ip_address
}
