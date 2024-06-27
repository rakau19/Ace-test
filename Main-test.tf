# Define the local variables
locals {
  address_space_vnet_Connectivity   = "10.14.0.0/23"
  address_space_snet_GatewaySubnet  = "10.14.0.0/24"
  address_space_snet_FirewallSubnet = "10.14.1.64/26"
  address_space_snet_BastionSubnet  = "10.14.1.128/26"
  address_space_snet_AppGWSubnet    = "10.14.1.192/26"
  address_space_vnet_Production     = "10.15.0.0/24"
  address_space_snet_WebApp         = "10.15.0.0/26"
  address_space_snet_DB             = "10.15.0.64/26"
}

###############################################################################
# Create a resource group CONNECTIVITY
###############################################################################
resource "azurerm_resource_group" "connectivity" {
  name     = var.connectivity_rg
  location = var.location
  tags = {
    environment = "AceCorp"
  }
}

###############################################################################
# Create a resource group PRODUCTION
###############################################################################
resource "azurerm_resource_group" "production" {
  name     = var.production_rg
  location = var.location
  tags = {
    environment = "AceCorp"
  }
}

###############################################################################
# Create Connectivity vnet
###############################################################################
resource "azurerm_virtual_network" "connectivity_vnet" {
  name                = var.connectivity_vnet
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  address_space       = [local.address_space_vnet_Connectivity]
  tags = {
    environment = "AceCorp"
  }
}

###############################################################################
#Create  Vnet peering from Connectivity to Production
###############################################################################
resource "azurerm_virtual_network_peering" "cnct_prod_peer" {
  name                      = "${var.connectivity_vnet}-to-${var.production_vnet}"
  resource_group_name       = azurerm_resource_group.connectivity.name
  virtual_network_name      = azurerm_virtual_network.connectivity_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.production_vnet.id

}

###############################################################################
# Create Production vnet
###############################################################################
resource "azurerm_virtual_network" "production_vnet" {
  name                = var.production_vnet
  location            = azurerm_resource_group.production.location
  resource_group_name = azurerm_resource_group.production.name
  address_space       = [local.address_space_vnet_Production]
  tags = {
    environment = "AceCorp"
  }
}

###############################################################################
# Create  Vnet peering from Production to Connectivity
###############################################################################
resource "azurerm_virtual_network_peering" "prod_cnct_peer" {
  name                      = "${var.production_vnet}-to-${var.connectivity_vnet}"
  resource_group_name       = azurerm_resource_group.production.name
  virtual_network_name      = azurerm_virtual_network.production_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.connectivity_vnet.id
  
     depends_on = [azurerm_virtual_network.connectivity_vnet]
}

###############################################################################
# Create SUBNET - GatewaySubnet
###############################################################################
resource "azurerm_subnet" "GatewaySubnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.connectivity_vnet.name
  address_prefixes     = [local.address_space_snet_GatewaySubnet]
}

###############################################################################
# Create SUBNET - FirewallSubnet
###############################################################################
resource "azurerm_subnet" "FirewallSubnet" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.connectivity_vnet.name
  address_prefixes     = [local.address_space_snet_FirewallSubnet]
}

###############################################################################
# Create SUBNET - BastionSubnet
###############################################################################
resource "azurerm_subnet" "BastionSubnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.connectivity_vnet.name
  address_prefixes     = [local.address_space_snet_BastionSubnet]
}

###############################################################################
# Create Bastion
###############################################################################
resource "azurerm_public_ip" "bastion" {
  name                = var.pip_bastion
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "host_name" {
  name                = var.bastion_host_name
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.BastionSubnet.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

###############################################################################
# Create SUBNET - WebApp
###############################################################################
resource "azurerm_subnet" "WebAppSubnet" {
  name                 = var.WebAppSnet
  resource_group_name  = azurerm_resource_group.production.name
  virtual_network_name = azurerm_virtual_network.production_vnet.name
  address_prefixes     = [local.address_space_snet_WebApp]
}

###############################################################################
# Create SUBNET - AppGW
###############################################################################
resource "azurerm_subnet" "AppGW" {
  name                 = var.AppGwSnet
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.connectivity_vnet.name
  address_prefixes     = [local.address_space_snet_AppGWSubnet]
}

###############################################################################
# Create Connectivity Vnet Route Table 
###############################################################################
resource "azurerm_route_table" "connectivity_routetable" {
  name                          = var.connectivity_rt
  location                      = azurerm_resource_group.connectivity.location
  resource_group_name           = azurerm_resource_group.connectivity.name
  disable_bgp_route_propagation = false

  route {
    name           = var.route_cnct_name
    address_prefix = var.appgw_subnet_rt
    next_hop_type  = var.next_hop_type
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "connectivity_subnet" {
  subnet_id      = azurerm_subnet.AppGW.id
  route_table_id = azurerm_route_table.connectivity_routetable.id
}

###############################################################################
# Create Production Vnet Route Table
###############################################################################
resource "azurerm_route_table" "production_routetable" {
  name                          = var.production_rt
  location                      = azurerm_resource_group.production.location
  resource_group_name           = azurerm_resource_group.production.name
  disable_bgp_route_propagation = false

  route {
    name           = var.route_prod_name
    address_prefix = "0.0.0.0/0"
    next_hop_type  = var.next_hop_type
    next_hop_in_ip_address = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "WebApp_subnet" {
  subnet_id      = azurerm_subnet.WebAppSubnet.id
  route_table_id = azurerm_route_table.production_routetable.id
}

###############################################################################
# Create Azure Firewall
###############################################################################
resource "azurerm_ip_group" "infra_ip_group" {
  name                = "infra-ip-group"
  resource_group_name = azurerm_resource_group.production.name
  location            = azurerm_resource_group.production.location
  cidrs               = ["10.15.0.0/24"]
}

resource "azurerm_public_ip" "pip_azfw" {
  name                = var.pip_azfw_ipconfig
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall_policy" "azfw_policy" {
  name                     = var.policy_fw
  resource_group_name      = azurerm_resource_group.connectivity.name
  location                 = azurerm_resource_group.connectivity.location
  sku                      = var.firewall_sku_tier
  threat_intelligence_mode = "Alert"
}

resource "azurerm_firewall_policy_rule_collection_group" "net_policy_rule_collection_group" {
  name               = "DefaultNetworkRuleCollectionGroup"
  firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
  priority           = 200
  network_rule_collection {
    name     = "DefaultNetworkRuleCollection"
    action   = "Allow"
    priority = 200
    rule {
      name                  = "time-windows"
      protocols             = ["UDP"]
      source_ip_groups      = [azurerm_ip_group.infra_ip_group.id]
      destination_ports     = ["123"]
      destination_addresses = ["132.86.101.172"]
    }
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "app_policy_rule_collection_group" {
  name               = var.firewall_collection_group
  firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
  priority           = 300
  application_rule_collection {
    name     = "DefaultAppRuleCollection"
    action   = "Allow"
    priority = 500
    rule {
      name = "AllowWindowsUpdate"

      description = "Allow Windows Update"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups      = [azurerm_ip_group.infra_ip_group.id]
      destination_fqdn_tags = ["WindowsUpdate"]
    }
    rule {
      name        = "Global Rule"
      description = "Allow access to Microsoft.com"
      protocols {
        type = "Https"
        port = 443
      }
      destination_fqdns = ["*.microsoft.com"]
      terminate_tls     = false
      source_ip_groups  = [azurerm_ip_group.infra_ip_group.id]
    }
  }
}

resource "azurerm_firewall" "fw" {
  name                = var.firewall_name
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  
  ip_configuration {
    name                 = var.pip_azfw_ipconfig
    subnet_id            = azurerm_subnet.FirewallSubnet.id
    public_ip_address_id = azurerm_public_ip.pip_azfw.id
  }
  firewall_policy_id = azurerm_firewall_policy.azfw_policy.id
}

###############################################################################
# Create Azure Recovery Services Vault
###############################################################################
resource "azurerm_recovery_services_vault" "vault" {
  name                = var.rsv
  location            = azurerm_resource_group.production.location
  resource_group_name = azurerm_resource_group.production.name
  sku                 = "Standard"

  soft_delete_enabled = true
}

resource "azurerm_site_recovery_replication_policy" "policy" {
  name                                                 = "policy"
  resource_group_name                                  = azurerm_resource_group.production.name
  recovery_vault_name                                  = azurerm_recovery_services_vault.vault.name
  recovery_point_retention_in_minutes                  = 24 * 60
  application_consistent_snapshot_frequency_in_minutes = 4 * 60
}

###############################################################################
# Create Keyvault with new certificate
###############################################################################

resource "azurerm_key_vault" "key-vault" {
  name                       = var.keyvault_name
  location                   = azurerm_resource_group.production.location
  resource_group_name        = azurerm_resource_group.production.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Create",
      "Delete",
      "DeleteIssuers",
      "Get",
      "GetIssuers",
      "Import",
      "List",
      "ListIssuers",
      "ManageContacts",
      "ManageIssuers",
      "Purge",
      "SetIssuers",
      "Update",
    ]

    key_permissions = [
      "Backup",
      "Create",
      "Decrypt",
      "Delete",
      "Encrypt",
      "Get",
      "Import",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Sign",
      "UnwrapKey",
      "Update",
      "Verify",
      "WrapKey",
    ]

    secret_permissions = [
      "Backup",
      "Delete",
      "Get",
      "List",
      "Purge",
      "Recover",
      "Restore",
      "Set",
    ]
  }
}  

resource "azurerm_key_vault_certificate" "kv_create_certificate" {
  name         = var.keyvault_cert
  key_vault_id = azurerm_key_vault.key-vault.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 30
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = ["Ace-Market-ra.azurewebsites.net"]
      }

      subject            = "CN=hello-world"
      validity_in_months = 12
    }
  }
}

###############################################################################
# Create Azure Application Gateway
###############################################################################
resource "azurerm_public_ip" "pip_appgw" {
  name                = var.pip_fe_appgw
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  backend_address_pool_name      = "${azurerm_subnet.WebAppSubnet.name}-beap"
  frontend_port_name             = "${azurerm_subnet.GatewaySubnet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_subnet.GatewaySubnet.name}-feip"
  http_setting_name              = "${azurerm_subnet.GatewaySubnet.name}-be-htst"
  listener_name                  = "${azurerm_subnet.GatewaySubnet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_subnet.GatewaySubnet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_subnet.GatewaySubnet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = var.Appgw_name
  resource_group_name = azurerm_resource_group.connectivity.name
  location            = azurerm_resource_group.connectivity.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.AppGW.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.pip_appgw.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
    fqdns = ["Ace-Corp-ra.azurewebsites.net"]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 443
    protocol              = "Https"
    request_timeout       = 60
    pick_host_name_from_backend_address = true
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"     
  }

  request_routing_rule {
    name = local.request_routing_rule_name
    priority                   = 9
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}

###############################################################################
# Create App service plan and Web App
###############################################################################
resource "azurerm_service_plan" "webapp_plan" {
  name                = var.appserviceplan
  resource_group_name = azurerm_resource_group.production.name
  location            = azurerm_resource_group.production.location
  sku_name            = "B1"
  os_type             = "Windows"
}

resource "azurerm_windows_web_app" "Ace_Corp" {
  name                = var.webapp
  resource_group_name = azurerm_resource_group.production.name
  location            = azurerm_service_plan.webapp_plan.location
  service_plan_id     = azurerm_service_plan.webapp_plan.id

connection_string {
    name  = "SqlAzureconnectionstring"
    type  = "SQLAzure"
    value = "Server=tcp:${azurerm_mssql_server.sql_svr.fully_qualified_domain_name},1433;Initial Catalog=${azurerm_mssql_database.sql_db.name};Persist Security Info=False;User ID=${azurerm_mssql_server.sql_svr.administrator_login};Password=${azurerm_mssql_server.sql_svr.administrator_login_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
 }

  site_config {
    minimum_tls_version = "1.2"
  }
}

###############################################################################
# Create Azure SQL Database
###############################################################################
resource "azurerm_mssql_server" "sql_svr" {
  name                         = var.sql_server
  resource_group_name          = azurerm_resource_group.production.name
  location                     = azurerm_resource_group.production.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Letmein@@1234!!"

  tags = {
    environment = "production"
  }
}

resource "random_string" "resource_code" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_storage_account" "prod_sa" {
  name                     = var.sa_resource
  resource_group_name      = azurerm_resource_group.production.name
  location                 = azurerm_resource_group.production.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_mssql_database" "sql_db" {
  name           = var.sql_resource
  server_id      = azurerm_mssql_server.sql_svr.id

  tags = {
    environment = "production"
  }
}

resource "azurerm_mssql_firewall_rule" "allow_all_azure_ips" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sql_svr.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

###############################################################################
# Create Storage Account
###############################################################################

resource "azurerm_storage_account" "tfstate_ace" {
  name                     = var.sa_resource
  resource_group_name      = azurerm_resource_group.production.name
  location                 = azurerm_resource_group.production.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
