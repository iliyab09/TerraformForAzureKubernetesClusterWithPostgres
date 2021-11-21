provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "k8sReasource" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_kubernetes_cluster" "k8sCluster" {
  name                = "example-aks1"
  location            = azurerm_resource_group.k8sReasource.location
  resource_group_name = azurerm_resource_group.k8sReasource.name
  dns_prefix          = "exampleaks1"

  default_node_pool {
    name       = "node"
    node_count = var.nodes
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "StageCL"
  }

  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "Standard"
  }
}

output "client_certificate" {
  value = azurerm_kubernetes_cluster.k8sCluster.kube_config.0.client_certificate
}

output "kube_config" {
  value = azurerm_kubernetes_cluster.k8sCluster.kube_config_raw

  sensitive = true
}





resource "azurerm_container_registry" "acr" {
  name                = "containerRegistryEliB"
  resource_group_name = azurerm_resource_group.k8sReasource.name
  location            = azurerm_resource_group.k8sReasource.location
  sku                 = "Premium"
  admin_enabled       = false
  
}




resource "azurerm_postgresql_server" "ps_stage" {
  name                = "ps-db-stage"
  location            = azurerm_resource_group.k8sReasource.location
  resource_group_name = azurerm_resource_group.k8sReasource.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = var.DBuserName
  administrator_login_password = var.DBpass
  version                      = "11"
  ssl_enforcement_enabled      = false
}


resource "azurerm_postgresql_firewall_rule" "postgres_firewall" {
  name                = "stage_rule"
  resource_group_name = azurerm_resource_group.k8sReasource.name
  server_name         = azurerm_postgresql_server.ps_stage.name
  start_ip_address    = "20.50.159.1"#azurerm_public_ip.public_ip.ip_address#data.azurerm_public_ip.ip_data.ip_address
  end_ip_address      = "20.50.159.1"#azurerm_public_ip.public_ip.ip_address#data.azurerm_public_ip.ip_data.ip_address
  
}