resource "azurerm_resource_group" "kube" {
  name     = "amina-rg-kube"
  location = "francecentral"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "kubevnet" {
  name                = "kubevnet"
  resource_group_name = azurerm_resource_group.kube.name
  location            = azurerm_resource_group.kube.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "kubesub" {
  name                 = "ksubnet"
  resource_group_name  = azurerm_resource_group.kube.name
  virtual_network_name = azurerm_virtual_network.kubevnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_security_group" "kube" {
  name                = "kubesng"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  security_rule {
       name = "http"
       priority = 100
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "80"
       source_address_prefix = var.whitelisted_ip
       destination_address_prefix = "*"
   }

   security_rule {
       name = "https"
       priority = 200
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "443"
       source_address_prefix = var.whitelisted_ip
       destination_address_prefix = "*"
   }

   security_rule {
       name = "ssh"
       priority = 300
       direction = "Inbound"
       access = "Allow"
       protocol = "Tcp"
       source_port_range = "*"
       destination_port_range = "22"
       source_address_prefix = var.whitelisted_ip
       destination_address_prefix = "*"
   }

   security_rule {
       name = "all"
       priority = 400
       direction = "Inbound"
       access = "Allow"
       protocol = "*"
       source_port_range = "*"
       destination_port_range = "*"
       source_address_prefix = "VirtualNetwork"
       destination_address_prefix = "VirtualNetwork"
   }
}
resource "azurerm_public_ip" "masterip" {
   name = "ctlpubip"
   location = azurerm_resource_group.kube.location
   resource_group_name = azurerm_resource_group.kube.name
   allocation_method = "Static"
}

resource "azurerm_network_interface" "kbnic" {
  name                = "knic1"
  location            = azurerm_resource_group.kube.location
  resource_group_name = azurerm_resource_group.kube.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.kubesub.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.masterip.id
  }
}

resource "tls_private_key" "sshctl" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "azurerm_linux_virtual_machine" "ctlplane" {
  name                = "master.kubernetes.lab"
  resource_group_name = azurerm_resource_group.kube.name
  location            = azurerm_resource_group.kube.location
  size                = "Standard_D2ds_v4"
  admin_username      = "azureuser"
  admin_password = "@Azurev69007"
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.kbnic.id,
  ]

  admin_ssh_key {
  username   = "azureuser"
  public_key = tls_private_key.sshctl.public_key_openssh
}

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }
  tags = {
     role = "master.kubernetes.lab"
   }
}

resource "azurerm_public_ip" "workersip" {
   count = 2
   name = "ctlpubip${count.index}"
   location = azurerm_resource_group.kube.location
   resource_group_name = azurerm_resource_group.kube.name
   allocation_method = "Static"
}
resource "azurerm_network_interface" "kwk" {
   count               = 2
   name                = "acctni${count.index}"
   location            = azurerm_resource_group.kube.location
   resource_group_name = azurerm_resource_group.kube.name

   ip_configuration {
     name                          = "testConfiguration"
     subnet_id                     = azurerm_subnet.kubesub.id
     private_ip_address_allocation = "Dynamic"
     public_ip_address_id = element(azurerm_public_ip.workersip.*.id, count.index)
   }
 }

 resource "azurerm_managed_disk" "test" {
   count                = 2
   name                 = "datadisk_existing_${count.index}"
   location             = azurerm_resource_group.kube.location
   resource_group_name  = azurerm_resource_group.kube.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = "20"
 }

 resource "azurerm_availability_set" "avset" {
   name                         = "avset"
   location                     = azurerm_resource_group.kube.location
   resource_group_name          = azurerm_resource_group.kube.name
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
 }

 resource "azurerm_linux_virtual_machine" "workers" {
   count                 = 2
   name                  = "vmaminab11n${count.index}"
   location              = azurerm_resource_group.kube.location
   availability_set_id   = azurerm_availability_set.avset.id
   resource_group_name   = azurerm_resource_group.kube.name
   admin_username        = "azureuser"
   network_interface_ids = [element(azurerm_network_interface.kwk.*.id, count.index)]
   size               = "Standard_D2ds_v4"

   # Uncomment this line to delete the OS disk automatically when deleting the VM
  #delete_os_disk_on_termination = true

   # Uncomment this line to delete the data disks automatically when deleting the VM
  #delete_data_disks_on_termination = true

os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

 source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }

admin_ssh_key {
  username   = "azureuser"
  public_key = tls_private_key.sshctl.public_key_openssh
}

   tags = {
     role = "Workers"
   }
}


resource "azurerm_network_interface_security_group_association" "linkctlnic" {
  network_interface_id      = azurerm_network_interface.kbnic.id
  network_security_group_id = azurerm_network_security_group.kube.id
 }

resource "azurerm_network_interface_security_group_association" "linkwks1" {
  network_interface_id      = azurerm_network_interface.kwk[0].id
  network_security_group_id = azurerm_network_security_group.kube.id
 }

resource "azurerm_network_interface_security_group_association" "linkwks2" {
  network_interface_id      = azurerm_network_interface.kwk[1].id
  network_security_group_id = azurerm_network_security_group.kube.id
 }

  }

 source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_5-gen2"
    version   = "latest"
  }

admin_ssh_key {
  username   = "azureuser"
  public_key = tls_private_key.sshwks.public_key_openssh
}

   tags = {
     role = "Workers"
   }
 }
