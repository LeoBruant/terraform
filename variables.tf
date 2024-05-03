variable "admin" {
  description = "Admin credentials"

  type = object({
    username = string
    password = string
  })
}

variable "location" {
  default     = "francecentral"
  description = "VM location"
  type        = string
}

variable "os" {
  default = {
    offer     = "0001-com-ubuntu-server-jammy"
    publisher = "Canonical"
    sku       = "22_04-lts"
    version   = "latest"
  }

  description = "OS config"

  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}

variable "prefix" {
  default     = "azure"
  description = "Ressources prefix"
  type        = string
}

variable "ssh_key" {
  description = "SSH key location"
  type        = string
}
