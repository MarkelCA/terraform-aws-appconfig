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

# module "deactivated_appconfig" {
#   source = "../../"
#
#   name   = local.name
#   create = false
# }
#
module "appconfig" {
  source = "../appconfig-module/"

  name        = local.name
  description = "AppConfig hosted - ${local.name}"

  # environments
  environments = {
    nonprod = {
      name        = "nonprod"
      description = "NonProd environment - ${local.name}"
    },
    prod = {
      name        = "prod"
      description = "Prod environment - ${local.name}"
    }
  }

  # hosted config version
  use_hosted_configuration           = true
  hosted_config_version_content_type = "application/json"
  hosted_config_version_content      = file("../configs/config.json")

  # configuration profile
  config_profile_validator = [{
    type    = "JSON_SCHEMA"
    content = file("../configs/config_validator.json")
    }, {
    type    = "LAMBDA"
    content = module.validate_lambda.lambda_function_arn
  }]

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################

data "archive_file" "lambda_handler" {
  type        = "zip"
  source_file = "../configs/validate.py"
  output_path = "../configs/validate.zip"
}

module "validate_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = local.name
  description   = "Configuration semantic validation lambda"
  handler       = "validate.handler"
  runtime       = "python3.9"
  publish       = true
  memory_size   = 512
  timeout       = 120

  cloudwatch_logs_retention_in_days = 7
  attach_tracing_policy             = true
  tracing_mode                      = "Active"

  create_package         = false
  local_existing_package = data.archive_file.lambda_handler.output_path

  allowed_triggers = {
    AppConfig = {
      service = "appconfig"
    },
  }

  tags = local.tags
}
