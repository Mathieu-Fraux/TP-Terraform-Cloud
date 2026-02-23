# création du Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location

  tags = {
    environment = "tp"
    managed_by  = "terraform"
  }
}

# création du Réseau Virtuel 
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# création du Sous-réseau
resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# création du Pare-feu 
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Regle 1 : Autoriser le SSH (Port 22)
  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Regle 2 : Autoriser le web HTTP (Port 80)
  security_rule {
    name                       = "allow-http"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Regle 3 : Tout bloquer par défaut 
  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Association du Pare-feu au Sous-réseau
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# PARTIE 4 : LES MACHINES VIRTUELLES
# =====================================

# CONFIGURATION VM 1 

# 1 Carte réseau de la VM 1
resource "azurerm_network_interface" "nic1" {
  name                = "${var.prefix}-nic-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 2 La Machine Virtuelle 1
resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "${var.prefix}-vm-1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic1.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Terraform va chercher la clé que tu viens de créer
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Le script magique qui s'exécute au premier démarrage
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "<h1>Hello from ${var.prefix}-vm-1</h1>" > /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  )
}

# --- CONFIGURATION VM 2 ---

# 3 Carte réseau de la VM 2
resource "azurerm_network_interface" "nic2" {
  name                = "${var.prefix}-nic-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

# 4 La Machine Virtuelle 2
resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "${var.prefix}-vm-2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic2.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Même script, mais on change le nom de la page HTML pour différencier les deux vm
  custom_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "<h1>Hello from ${var.prefix}-vm-2</h1>" > /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF
  )
}

# PARTIE 5 : LE LOAD BALANCER
# ==========================================

# 1 L'IP publique du Load Balancer
resource "azurerm_public_ip" "lb_pip" {
  name                = "${var.prefix}-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 2 Le Load Balancer lui-même
resource "azurerm_lb" "lb" {
  name                = "${var.prefix}-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

# 3 Le Pool 
resource "azurerm_lb_backend_address_pool" "backend_pool" {
  name            = "${var.prefix}-backend-pool"
  loadbalancer_id = azurerm_lb.lb.id
}

# 4 Association de la VM 1 au Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "nic1_assoc" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# 5 Association de la VM 2 au Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "nic2_assoc" {
  network_interface_id    = azurerm_network_interface.nic2.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

# 6 La Sonde de santé Pour vérifier si les VMs sont vivantes
resource "azurerm_lb_probe" "http_probe" {
  name            = "${var.prefix}-http-probe"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Http"
  port            = 80
  request_path    = "/"
}

# 7 routage (Rediriger le port 80 public vers le port 80 des VMs)
resource "azurerm_lb_rule" "http_rule" {
  name                           = "${var.prefix}-http-rule"
  loadbalancer_id                = azurerm_lb.lb.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.backend_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}