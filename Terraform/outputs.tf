output "resource_group_id" {
  value = azurerm_resource_group.rg.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}

output "load_balancer_public_ip" {
  value       = azurerm_public_ip.lb_pip.ip_address
  description = "L'adresse IP publique "
}