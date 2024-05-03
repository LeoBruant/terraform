resource "azurerm_resource_group" "main" {
  location = var.location
  name     = "${var.prefix}-resources"
}

resource "azurerm_virtual_network" "main" {
  address_space       = ["10.0.0.0/22"]
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-network"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_group" "main" {
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-nsg"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_network_security_rule" "main" {
  access                      = "Allow"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  direction                   = "Outbound"
  name                        = "${var.prefix}-nsg-rule"
  network_security_group_name = azurerm_network_security_group.main.name
  priority                    = 100
  protocol                    = "Tcp"
  resource_group_name         = azurerm_resource_group.main.name
  source_address_prefix       = "*"
  source_port_ranges          = ["80", "443"]
}

resource "azurerm_subnet" "internal" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
}

resource "azurerm_public_ip" "main" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-ip"
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface" "main" {
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
    subnet_id                     = azurerm_subnet.internal.id
  }
}

resource "azurerm_ssh_public_key" "main" {
  location            = azurerm_resource_group.main.location
  name                = "${var.prefix}-ssh"
  public_key          = file("${var.ssh_key}.pub")
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_linux_virtual_machine" "main" {
  admin_password = var.admin.password

  admin_ssh_key {
    public_key = azurerm_ssh_public_key.main.public_key
    username   = var.admin.username
  }

  admin_username                  = var.admin.username
  disable_password_authentication = true
  location                        = azurerm_resource_group.main.location
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  size                            = "Standard_D2s_v3"
  network_interface_ids           = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer     = var.os.offer
    publisher = var.os.publisher
    sku       = var.os.sku
    version   = var.os.version
  }
}

resource "null_resource" "startup" {
  connection {
    host        = azurerm_public_ip.main.ip_address
    private_key = file(var.ssh_key)
    type        = "ssh"
    user        = var.admin.username
  }

  depends_on = [azurerm_linux_virtual_machine.main]

  provisioner "remote-exec" {
    script = "startup.sh"
  }

  triggers = {
    startup = file("startup.sh")
  }
}
