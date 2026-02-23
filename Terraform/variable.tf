variable "location" {
  type        = string
  description = "Région Azure"
  default     = "switzerlandnorth"
}

variable "prefix" {
  type        = string
  description = "Préfixe pour le nom des ressources"
  default    ="Limayrac"
}
  variable "subscription_id" {
  type        = string
  description = "ID de la souscription Azure"
}