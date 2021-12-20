# Configure the Microsoft Azure Provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}
provider "azurerm" {
  features {}
}
## <https://www.terraform.io/docs/providers/azurerm/r/resource_group.html>
resource "azurerm_resource_group" "rg" {
  name     = "EmbeddedBella"
  location = "eastus"
}

## <https://www.terraform.io/docs/providers/azurerm/r/availability_set.html>
resource "azurerm_availability_set" "DemoAset" {
  name                = "demoAset"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

## <https://www.terraform.io/docs/providers/azurerm/r/virtual_network.html>
resource "azurerm_virtual_network" "vnet" {
  name                = "vNet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

## <https://www.terraform.io/docs/providers/azurerm/r/subnet.html> 
resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.rg.name 
  virtual_network_name = azurerm_virtual_network.vnet.name 
  address_prefixes       = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "ipaddress" {
  name                = "PublicIp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}

output "public_ip_server" {
  value = azurerm_public_ip.ipaddress.ip_address
}

## <https://www.terraform.io/docs/providers/azurerm/r/network_interface.html>
resource "azurerm_network_interface" "interface" {
  name                = "interface"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name 

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id 
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ipaddress.id
  }
}

## <https://www.terraform.io/docs/providers/azurerm/r/windows_virtual_machine.html>
resource "azurerm_linux_virtual_machine" "azurevmbella" {
  name                = "AzureVMBella"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = var.SERVER_USERNAME
  admin_password      = var.SERVER_PWD
  disable_password_authentication = false
  availability_set_id = azurerm_availability_set.DemoAset.id 
  network_interface_ids = [
    azurerm_network_interface.interface.id
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
