# The public SSH key to use
variable "public_key_path" {
  description = "Public SSH Key to use (e.g: ~/.ssh/theseus.pub)"
  default = "~/.ssh/theseus.pub"
}

# Resource Group Prefix
variable "resource_group_name_prefix" {
  default       = "theseus"
  description   = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

# Resource Group Location
variable "resource_group_location" {
  default       = "eastus"
  description   = "Location of the resource group."
}