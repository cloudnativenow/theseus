# Save Terraform State to Azure Storage
terraform {
  backend "azurerm" {
    key                  = "terraform.tfstate"
  }
}