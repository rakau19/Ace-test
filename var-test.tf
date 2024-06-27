# Variables File

variable "location" {
  type        = string
  description = "Azure region for deployment of resources."
}

variable "connectivity_rg" {
  type        = string
  description = "Azure connectivity environment for deployment of resources."
}

variable "production_rg" {
  type        = string
  description = "Azure production environment for deployment of resources."
}

variable "connectivity_vnet" {
  type        = string
  description = "Create connectivity Vnet."
}

variable "production_vnet" {
  type        = string
  description = "Create production Vnet."
}

variable "pip_bastion" {
  type        = string
  description = "Azure Bastion public IP ."
}

variable "bastion_host_name" {
  type        = string
  description = "Azure Bastion host name ."
}


variable "AppGwSnet" {
  type        = string
  description = "Azure Application Gateway Subnet ."
}

variable "WebAppSnet" {
  type        = string
  description = "Azure Web Application Subnet ."
}

variable "SubIDs" {
  type        = string
  default     = ""
  description = "Azure Subscription ID."
}

variable "connectivity_rt" {
  type        = string
  description = "Azure Route Table for connectivity subnet"
}

variable "production_rt" {
  type        = string
  description = "Azure Route Table for production subnet"
}

variable "appgw_subnet_rt" {
  type        = string
  description = "Azure Route Table for application gateway subnet"
}

variable "next_hop_type" {
  type        = string
  description = "Azure Route Table next hop type"
}

variable "route_cnct_name" {
  type        = string
  description = "Azure Connectivity RT route name"
}

variable "route_prod_name" {
  type        = string
  description = "Azure Production RT route name"
}

variable "firewall_sku_tier" {
  type        = string
  description = "Firewall SKU."
  default     = "Standard" # Valid values are Standard and Premium
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "The sku must be one of the following: Standard, Premium"
  }
}

variable "policy_fw" {
  type        = string
  description = "Azure Firewall Policy"
}

variable "firewall_collection_group" {
  type        = string
  description = "Azure Firewall Rules Collection Group"
}

variable "pip_azfw_ipconfig" {
  type        = string
  description = "Azure Firewall Public IP Configuration"
}

variable "firewall_name" {
  type        = string
  description = "Azure Firewall name"
}

variable "keyvault_name" {
  type        = string
  description = "Azure Key Vault name"
}

variable "keyvault_cert" {
  type        = string
  description = "Azure Web App Certificate "
}

variable "mi_appgw_keyvault" {
  type        = string
  description = "Azure Managed Identity, TLS/SSL certificate "
}

variable "pip_fe_appgw" {
  type        = string
  default     = "pip-fe-appgw-cnct-cus-01"
  description = "Azure AppGW Front end Public IP "
}

variable "Appgw_name" {
  type        = string
  description = "Azure AppGW create resource "
}

variable "rsv" {
  type        = string
  description = "Azure Recovery Service Vault create resource "
}

variable "appserviceplan" {
  type        = string
  description = "Azure App Service plan name "
}

variable "webapp" {
  type        = string
  description = "Azure Web Application name "
}

variable "sa_resource" {
  type        = string
  description = "Azure storage acccount name "
}

variable "sql_server" {
  type        = string
  description = "Azure SQL server name "
}

variable "sql_resource" {
  type        = string
  description = "Azure SQL DB name "
}

