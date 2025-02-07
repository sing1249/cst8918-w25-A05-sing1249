# Configure the Terraform runtime requirements.
terraform {
  required_version = ">= 1.1.0"

  required_providers {
    # Azure Resource Manager provider and version
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "2.3.3"
    }
  }
}

# Define providers and their config params
provider "azurerm" {
  # Leave the features block empty to accept all defaults
  features {}
}

provider "cloudinit" {
  # Configuration options
}


# Defining resource group
resource "azurerm_resource_group" "rg" {
  name     = "${var.labelPrefix}-A05-RG"
  location = var.region
}


# Defining Public IP Address
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.labelPrefix}-A05-PIP"
  resource_group_name = azurerm_resource_group.rg.name 
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Dynamic"
}

# Defining Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.labelPrefix}-A05-VNet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Defining Subnet
resource "azurerm_subnet" "subnet" {
  name                 = "${var.labelPrefix}-A05-Subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Defining Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.labelPrefix}-A05-NSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


# Defining Virtual Network Interface Card (NIC)
resource "azurerm_network_interface" "nic" {
  name                = "${var.labelPrefix}-A05-NIC"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# Associate NSG with NIC
resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# Defining a data resource using the cloudinit_config resource type
data "cloudinit_config" "webserver" {
  gzip          = false
  base64_encode = false

  part {
    content_type = "text/x-shellscript"
    filename     = "init.sh"
    content      = file("${path.module}/init.sh")
  }
}


# Defining Virtual Machine
resource "azurerm_linux_virtual_machine" "webserver" {
  name                = "${var.labelPrefix}-A05-VM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  admin_ssh_key {
    username   = var.admin_username
    public_key = file("/home/sing1249/.ssh/id_rsa.pub")
  }
  custom_data = data.cloudinit_config.webserver.rendered
}


# Output Values
output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_public_ip.public_ip.ip_address
}

