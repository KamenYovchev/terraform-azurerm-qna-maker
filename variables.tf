variable "name" {}

# variable "KBFileName" {
#   description = "The file name of the knowledgebase template to use."
# }

# variable "KBLanguageCode" {
#   description = "The language code to use when naming the KB (EN, FR)."
# }


variable "resource_group_name" {}

variable "location" {}

variable "tier" {}

variable "size" {}

variable "search_sku" {
  default = "standard"
  description = "The sku tos use for the azure search service"
}

variable "account_sku" {
  default = "S0"
  description = "The sku to use for the azure congative account"
}

variable "plan_id" {
  default = ""
  description = "The app service plan to use.  If none is passed it will create one"
}
