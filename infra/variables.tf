variable "location" {
  type        = string
  description = "Azure region for the website resources"
  default     = "centralindia"
}

locals {
  tags = {
    project   = "cicd-lab1"
    managedBy = "terraform"
  }
}
