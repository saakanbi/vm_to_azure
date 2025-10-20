variable "project" {
  type    = string
  default = "vm2cloud"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "node_count" {
  type    = number
  default = 2
}

variable "acr_sku" {
  type    = string
  default = "Basic"
}
