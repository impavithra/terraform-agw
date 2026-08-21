variable "location" {
  default = "East US"
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VMs"
  sensitive   = true
}
