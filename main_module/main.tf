terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.62.1"
    }
  }
}

provider "azurerm" {
  features {
    
  }
}

module "vms" {
    source = "github.com/Nevralgie/TFxAnsxK8s/vms"
}

