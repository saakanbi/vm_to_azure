# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-rg"
  location = var.location
}

# Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = "${var.project}acr" # must be globally unique, lowercase
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = true
}

# Log Analytics (for AKS insights)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.project}-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.project}-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.project

  default_node_pool {
    name       = "system"
    node_count = var.node_count
    vm_size    = "Standard_D2s_v6"
  }

  identity {
    type = "SystemAssigned"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  }
}

# Allow AKS to pull images from ACR
resource "azurerm_role_assignment" "aks_pull_acr" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "resource_group" { value = azurerm_resource_group.rg.name }
output "acr_name" { value = azurerm_container_registry.acr.name }
output "aks_name" { value = azurerm_kubernetes_cluster.aks.name }
