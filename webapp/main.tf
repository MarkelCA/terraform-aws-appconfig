provider "aws" {
  region = local.region
}

locals {
  region = "us-east-1"
  name   = "appconfig-ex-${replace(basename(path.cwd), "_", "-")}"

  tags = {
    Name       = local.name
    Example    = local.name
    Repository = "https://github.com/terraform-aws-modules/terraform-aws-appconfig"
  }
}

################################################################################
# AppConfig
################################################################################

module "deactivated_appconfig" {
  source = "../appconfig-module"

  name   = "Myy deactivated!"
  create = false
}

module "appconfig" {
  source = "../appconfig-module/"

  name        = local.name
  description = "AppConfig hosted - ${local.name}"

  # environments
  environments = {
    test = {
      name        = "test"
      description = "Test environment - ${local.name}"
    },
    prod = {
      name        = "prod"
      description = "Prod environment - ${local.name}"
    }
    local = {
      name        = "local"
      description = "Local environment - ${local.name}"
    }
  }

  # hosted config version
  use_hosted_configuration           = true
  feature_flags_app_name = "Webapp Feature Flags"
  feature_flags_app_description = "The description of my feature flags application"
  hosted_config_version_content_type = "application/json"
  hosted_config_version_content      = file("../configs/config.json")


  tags = local.tags
}
