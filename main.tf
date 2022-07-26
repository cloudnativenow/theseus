# Create Unique Resource Group Name
resource "random_pet" "rg-name" {
  length = 1
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name = "theseus-${random_pet.rg-name.id}-rg"
  location  = var.resource_group_location
}

# Create virtual network
resource "azurerm_virtual_network" "theseus-vnet" {
  name                = "theseus-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Create subnet
resource "azurerm_subnet" "theseus-subnet" {
  name                 = "theseus-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.theseus-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "theseus-pip" {
  name                = "theseus-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "theseus-nsg" {
  name                = "theseus-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "theseus-nic" {
  name                = "theseus-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "theseus-nic-config"
    subnet_id                     = azurerm_subnet.theseus-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.theseus-pip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.theseus-nic.id
  network_security_group_id = azurerm_network_security_group.theseus-nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }
  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "theseus-storage" {
  name                     = "diag${random_id.randomId.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create (and display) an SSH key
# resource "tls_private_key" "example_ssh" {
#   algorithm = "RSA"
#   rsa_bits  = 4096
# }

# Create virtual machine
resource "azurerm_linux_virtual_machine" "theseus-vm" {
  name                  = "theseus-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.theseus-nic.id]
  size                  = "Standard_DS1_v2"
  os_disk {
    name                 = "theseus-os"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }
  computer_name                   = "theseus-vm"
  admin_username                  = "azureuser"
  disable_password_authentication = true
  admin_ssh_key {
    username   = "azureuser"
    # public_key = tls_private_key.example_ssh.public_key_openssh
    public_key = file(var.public_key_path)
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.theseus-storage.primary_blob_endpoint
  }
}