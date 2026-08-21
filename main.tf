# =========================================================
# RESOURCE GROUP
# =========================================================

resource "azurerm_resource_group" "rg" {
  name     = "rg-agw-demo"
  location = var.location
}

resource "azurerm_public_ip" "vm1_public_ip" {
  name                = "vm1-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}
# =========================================================
# VNET 1 - APPLICATION GATEWAY NETWORK
# =========================================================

resource "azurerm_virtual_network" "agw_vnet" {
  name                = "agw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = ["10.0.0.0/16"]
}


# =========================================================
# APPLICATION GATEWAY SUBNET
# =========================================================

resource "azurerm_subnet" "agw_subnet" {
  name                 = "agw-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.agw_vnet.name

  address_prefixes = ["10.0.1.0/24"]
}


# =========================================================
# VM1 SUBNET
# =========================================================

resource "azurerm_subnet" "vm1_subnet" {
  name                 = "vm1-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.agw_vnet.name

  address_prefixes = ["10.0.2.0/24"]
}


# =========================================================
# VNET 2 - SECOND NETWORK
# =========================================================

resource "azurerm_virtual_network" "backend_vnet" {
  name                = "backend-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  address_space = ["10.1.0.0/16"]
}


resource "azurerm_subnet" "vm2_subnet" {
  name                 = "vm2-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.backend_vnet.name

  address_prefixes = ["10.1.1.0/24"]
}


# =========================================================
# VNET PEERING
# =========================================================

resource "azurerm_virtual_network_peering" "agw_to_backend" {
  name                      = "agw-to-backend"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.agw_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.backend_vnet.id

  allow_virtual_network_access = true
}


resource "azurerm_virtual_network_peering" "backend_to_agw" {
  name                      = "backend-to-agw"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.backend_vnet.name
  remote_virtual_network_id = azurerm_virtual_network.agw_vnet.id

  allow_virtual_network_access = true
}


# =========================================================
# PUBLIC IP FOR APPLICATION GATEWAY
# =========================================================

resource "azurerm_public_ip" "agw_public_ip" {
  name                = "agw-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}


# =========================================================
# PUBLIC IP FOR VM2
# =========================================================

resource "azurerm_public_ip" "vm2_public_ip" {
  name                = "vm2-public-ip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  allocation_method = "Static"
  sku               = "Standard"
}


# =========================================================
# NSG FOR VM1
# =========================================================

resource "azurerm_network_security_group" "vm1_nsg" {
  name                = "vm1-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-Tomcat-From-AGW"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"

  }

security_rule {
  name                       = "Allow-Tomcat-Internet-Test"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
}


# =========================================================
# NSG FOR VM2
# =========================================================

resource "azurerm_network_security_group" "vm2_nsg" {
  name                = "vm2-nsg"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-Tomcat-From-AGW"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
security_rule {
  name                       = "Allow-Tomcat-Internet-Test"
  priority                   = 120
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "8080"
  source_address_prefix      = "*"
  destination_address_prefix = "*"
}
}


# =========================================================
# VM1 NIC
# =========================================================

resource "azurerm_network_interface" "vm1_nic" {
  name                = "vm1-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

ip_configuration {
  name                          = "internal"
  subnet_id                     = azurerm_subnet.vm1_subnet.id
  private_ip_address_allocation = "Dynamic"
  public_ip_address_id          = azurerm_public_ip.vm1_public_ip.id
}
}
resource "azurerm_network_interface_security_group_association" "vm1_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm1_nic.id
  network_security_group_id = azurerm_network_security_group.vm1_nsg.id
}

# =========================================================
# VM1
# =========================================================

resource "azurerm_linux_virtual_machine" "vm1" {
  name                = "tomcat-vm1"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  size = "Standard_D2s_v7"

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm1_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash

    apt-get update
    apt-get install -y tomcat10

    mkdir -p /var/lib/tomcat10/webapps/ROOT

    cat > /var/lib/tomcat10/webapps/ROOT/index.html <<'HTML'
    <html>
    <body>
    <h1>Tomcat Application - VM1</h1>
    <p>Traffic reached VM1 through Application Gateway.</p>
    </body>
    </html>
    HTML

    systemctl restart tomcat10
  EOF
  )
}


# =========================================================
# VM2 NIC
# =========================================================

resource "azurerm_network_interface" "vm2_nic" {
  name                = "vm2-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm2_subnet.id
    private_ip_address_allocation = "Dynamic"

    public_ip_address_id = azurerm_public_ip.vm2_public_ip.id
  }
}


resource "azurerm_network_interface_security_group_association" "vm2_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.vm2_nic.id
  network_security_group_id = azurerm_network_security_group.vm2_nsg.id
}


# =========================================================
# VM2
# =========================================================

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "tomcat-docker-vm"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  size = "Standard_D2s_v7"

  admin_username = var.admin_username
  admin_password = var.admin_password

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.vm2_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash

    apt-get update
    apt-get install -y docker.io

    systemctl enable docker
    systemctl start docker

    mkdir -p /opt/tomcat-app

    cat > /opt/tomcat-app/index.html <<'HTML'
    <html>
    <body>
    <h1>Tomcat Application - VM2 Docker</h1>
    <p>Traffic reached the Docker Tomcat backend through Application Gateway.</p>
    </body>
    </html>
    HTML

    docker pull tomcat:10.1-jdk17-temurin

    docker run -d \
      --name tomcat \
      --restart always \
      -p 8080:8080 \
      -v /opt/tomcat-app:/usr/local/tomcat/webapps/ROOT \
      tomcat:10.1-jdk17-temurin
  EOF
  )
}


# =========================================================
# APPLICATION GATEWAY
# =========================================================

resource "azurerm_application_gateway" "agw" {

  name                = "agw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  # -------------------------------------------------------
  # Gateway subnet
  # -------------------------------------------------------

  gateway_ip_configuration {
    name      = "agw-ip-config"
    subnet_id = azurerm_subnet.agw_subnet.id
  }

  # -------------------------------------------------------
  # Frontend
  # -------------------------------------------------------

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend-ip"
    public_ip_address_id = azurerm_public_ip.agw_public_ip.id
  }

  # -------------------------------------------------------
  # Backend pool
  # -------------------------------------------------------

  backend_address_pool {
    name = "tomcat-backend"

    ip_addresses = [
      azurerm_network_interface.vm1_nic.private_ip_address,
      azurerm_network_interface.vm2_nic.private_ip_address
    ]
  }

  # -------------------------------------------------------
  # Backend settings
  # -------------------------------------------------------

  backend_http_settings {
    name                  = "tomcat-http-settings"
    cookie_based_affinity = "Disabled"

    port     = 8080
    protocol = "Http"

    request_timeout = 30
  }

  # -------------------------------------------------------
  # Health probe
  # -------------------------------------------------------

  probe {
    name                = "tomcat-health-probe"
    protocol            = "Http"
    path                = "/"
    interval            = 30
    timeout             = 10
    unhealthy_threshold = 3

    host = "127.0.0.1"

    match {
      status_code = ["200-399"]
    }
  }

  # -------------------------------------------------------
  # Listener
  # -------------------------------------------------------

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip"
    frontend_port_name             = "http-port"

    protocol = "Http"
  }

  # -------------------------------------------------------
  # Routing rule
  # -------------------------------------------------------

  request_routing_rule {
    name                       = "tomcat-routing-rule"
    priority                   = 100
    rule_type                  = "Basic"

    http_listener_name         = "http-listener"
    backend_address_pool_name  = "tomcat-backend"
    backend_http_settings_name = "tomcat-http-settings"
  }
}
