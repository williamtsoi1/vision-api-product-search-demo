variable "project_id" { 
    description = "Project to be created"
}

variable "region" {
    description = "region for services to be deployed to"
}

variable "billing_account_id" {
    description = "Billing Account ID"
}

variable "app_engine_region" { 
    description = "region for app engine. This could be different for the case of europe-west and us-central"
}