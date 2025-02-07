variable "labelPrefix" {
  description = "Prefix for resource naming"
}

variable "region" {
  description = "Azure Region"
  default     = "Canada Central"
}

variable "admin_username" {
  description = "Admin username for the resources"
  default     = "azureadmin"
}
