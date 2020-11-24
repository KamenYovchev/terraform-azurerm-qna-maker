//Removed plan per langauge
resource "azurerm_app_service_plan" "qna-maker" {
  count = var.plan_id == "" ? 1 : 0
  name                = "${var.name}-qna-plan-svc"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku {
    //Only get one Free/F1.  Shared/Free need use_32_bit_worker_process = true in the application service
    tier = var.tier
    size = var.size

  }
  tags = var.tags
}

resource "azurerm_application_insights" "qna-maker-ai" {
  name                = "${var.name}-qna-ai-svc"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  tags = var.tags
}

resource "random_string" "random" {
  length = 12
  special = false
  lower = true
  upper = false
}

resource "azurerm_search_service" "qna-maker-search" {
  name                = "${lower(replace(var.name,"/-*_*/",""))}-qna-ss-svc${random_string.random.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.search_sku
  tags = var.tags
}

//Does not like underscores in the name
resource "azurerm_app_service" "qna-maker-svc" {
  name                = "${var.name}-qna-app-svc"
  location            = var.location
  resource_group_name = var.resource_group_name
  app_service_plan_id = var.plan_id == "" ? azurerm_app_service_plan.qna-maker[0].id : var.plan_id

  site_config {
    dotnet_framework_version = "v4.0"
    cors {
      allowed_origins     = ["*"]
    }
  }

  app_settings = {
     "AzureSearchName" = azurerm_search_service.qna-maker-search.name
     "AzureSearchAdminKey": azurerm_search_service.qna-maker-search.primary_key
     "UserAppInsightsKey": azurerm_application_insights.qna-maker-ai.instrumentation_key
     "UserAppInsightsName": azurerm_application_insights.qna-maker-ai.name
     "UserAppInsightsAppId": azurerm_application_insights.qna-maker-ai.app_id
     "PrimaryEndpointKey": "${var.name}-svc-PrimaryEndpointKey"
     "SecondaryEndpointKey": "${var.name}-svc-SecondaryEndpointKey"
     "DefaultAnswer": "No good match found in KB.",
     "QNAMAKER_EXTENSION_VERSION": "latest"
  }

  depends_on = [
      azurerm_application_insights.qna-maker-ai,
      azurerm_app_service_plan.qna-maker,
      azurerm_search_service.qna-maker-search
  ]
  tags = var.tags
}

//Looks like ARM has the ability to specify a custom domain but not here so it will be https://westus.api.cognitive.microsoft.com/qnamaker/v4.0
//Taint does not tear this down but destroying the services will
resource "azurerm_cognitive_account" "qna-maker-account" {
  name                = "${var.name}-qna-account"
  location            = var.location
  resource_group_name = var.resource_group_name
  kind                = "QnAMaker"
  sku_name = var.account_sku
  qna_runtime_endpoint = "https://${azurerm_app_service.qna-maker-svc.default_site_hostname}"
  depends_on = [
      azurerm_app_service.qna-maker-svc
  ]
  tags = var.tags
}

output "app_srv" {
  value = azurerm_app_service.qna-maker-svc
}

output "plan_id" {
  value = var.plan_id == "" ? azurerm_app_service_plan.qna-maker[0].id : var.plan_id
}