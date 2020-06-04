terraform {
  required_version = ">= 0.12"
}

provider "azurerm" {
  version = "~> 2.10"
  features {}
}

# Define Kubernetes provider to use the AKS cluster
# provider "kubernetes" {
#   version = "~> 1.11"
#   host                   = azurerm_kubernetes_cluster.aks.kube_config.0.host
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate)
# }

variable "name_prefix" {
  type        = string
  description = "A prefix for the naming scheme as part of prefix-base-suffix."
}

variable "name_base" {
  type        = string
  description = "A base for the naming scheme as part of prefix-base-suffix."
}

variable "name_suffix" {
  type        = string
  description = "A suffix for the naming scheme as part of prefix-base-suffix."
}

variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "aks_version" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "node_count" {
  type        = number
  description = "The number of nodes to create in the default node pool."
  default     = 1
}

variable "node_vm_sku" {
  type        = string
  description = "The VM SKU to use for the default nodes."
}

variable "win_admin_username" {
  type        = string
  description = "A username to use if/when creating a Windows node pool (must be added at cluster creation time)."
}

variable "win_admin_password" {
  type        = string
  description = "A password to use if/when creating a Windows node pool (must be added at cluster creation time)."
}

locals {
  base_name = "${var.name_prefix}-${var.name_base}-${var.name_suffix}"

  cluster_subnet_name = "cluster-subnet"
}

module "service_principal" {
  source    = "./modules/service-principal"
  base_name = local.base_name
}

module "monitoring" {
  source         = "./modules/monitoring"
  base_name      = local.base_name
  resource_group = azurerm_resource_group.group.name
  location       = azurerm_resource_group.group.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.base_name}-vnet"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  address_space       = ["10.0.0.0/8"]
}

resource "azurerm_subnet" "cluster" {
  name                 = local.cluster_subnet_name
  resource_group_name  = azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.0.0/16"]
}

resource "azurerm_resource_group" "group" {
  name     = local.base_name
  location = var.location
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.base_name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  dns_prefix          = local.base_name
  kubernetes_version  = var.aks_version

  default_node_pool {
    name       = "lnx000"
    node_count = var.node_count
    vm_size    = var.node_vm_sku
    # node_taints
    # node_labels

    # Required for advanced networking
    vnet_subnet_id = azurerm_subnet.cluster.id
  }

  windows_profile {
    admin_username = var.win_admin_username
    admin_password = var.win_admin_password
  }

  service_principal {
    client_id     = module.service_principal.client_id
    client_secret = module.service_principal.client_secret
  }

  role_based_access_control {
    enabled = true
  }
  
  addon_profile {
    
    azure_policy {
      enabled = true
    }

    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = module.monitoring.workspace_id
    }
    # http_application_routing {
    #   enabled = true
    # }
  }

  network_profile {
    network_plugin     = "azure"
    service_cidr       = "172.16.0.0/16"
    dns_service_ip     = "172.16.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  depends_on = [
    module.service_principal.client_id
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "winnodepool" {
  name                  = "win001"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = var.node_vm_sku
  node_count            = 1
  os_type               = "Windows"

  # Required for advanced networking
  vnet_subnet_id = azurerm_subnet.cluster.id
}