output "account_id" {
  value = data.azurerm_client_config.current.client_id
}

output "resource_group_name" {
  value = [azurerm_resource_group.connectivity.name, azurerm_resource_group.production.name ]
}

output "virtual_network_name" {
  value = [azurerm_virtual_network.connectivity_vnet.name, azurerm_virtual_network.production_vnet.name ]
}

output "virtual_network_peering" {
  value = [azurerm_virtual_network_peering.prod_cnct_peer.name, azurerm_virtual_network_peering.cnct_prod_peer.name ]
}

output "subnet_name" {
  value = [azurerm_subnet.GatewaySubnet.name, azurerm_subnet.FirewallSubnet.name, azurerm_subnet.BastionSubnet.name, azurerm_subnet.WebAppSubnet.name ]
}

output "azurerm_route_table" {
  value = [azurerm_route_table.connectivity_routetable.name, azurerm_route_table.production_routetable.name ]
}

output "firewall_name" {
  value = azurerm_firewall.fw.name
}

output "azurerm_virtual_network_peering" {
  value = [azurerm_virtual_network_peering.cnct_prod_peer, azurerm_virtual_network_peering.prod_cnct_peer]
}

output "secret_identifier" {
  value = azurerm_key_vault_certificate.kv_create_certificate.secret_id
}

output "webapp_url" {
  value = azurerm_windows_web_app.Ace_Corp.default_hostname 
}