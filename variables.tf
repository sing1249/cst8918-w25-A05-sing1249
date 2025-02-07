variable "labelPrefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "region" {
  description = "Azure Region"
  type        = string
  default     = "Canada Central"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
}

