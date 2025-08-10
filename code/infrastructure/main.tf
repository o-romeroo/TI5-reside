terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location" {
  description = "Região da Azure para o deploy."
  default     = "East US"
}

variable "resource_group_name" {
  description = "Nome do grupo de recursos."
  default     = "rg-reside-app-pd"
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "main" {
  name                = "acrresideapp" 
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true 
}

resource "azurerm_container_app_environment" "main" {
  name                = "cae-reside-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_container_app" "backend" {
  name                         = "reside-backend"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password_secret_name = "acr-password" 
  }
  
  secret {
    name = "acr-password"
    value = azurerm_container_registry.main.admin_password
  }
  
  template {
    container {
      name   = "backend-container"
      image  = "${azurerm_container_registry.main.login_server}/backend:latest" 
      cpu    = 1.0
      memory = "2.0Gi"
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 8080
    transport                = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

resource "azurerm_container_app" "frontend" {
  name                         = "reside-frontend"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  registry {
    server   = azurerm_container_registry.main.login_server
    username = azurerm_container_registry.main.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.main.admin_password
  }

  template {
    container {
      name   = "frontend-container"
      image  = "${azurerm_container_registry.main.login_server}/frontend:latest" 
      cpu    = 0.25
      memory = "0.5Gi"
      
      env {
        name = "API_URL" 
        value = "https://${azurerm_container_app.backend.name}.${azurerm_container_app_environment.main.default_domain}"
      }
    }
  }

  ingress {
    allow_insecure_connections = false
    external_enabled          = true
    target_port              = 80
    transport                = "http"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

output "frontend_url" {
  value = "https://${azurerm_container_app.frontend.latest_revision_fqdn}"
}