# ============================================================================
# EXAMPLE: AWS ROUTE53
# ============================================================================
# This example shows how to use the DNS module with AWS Route53.
# You can use either JSON file or Terraform variables.
# ============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# Configure AWS provider
provider "aws" {
  region = var.aws_region

  # Option 1: Use AWS CLI credentials (recommended)
  # profile = "default"

  # Option 2: Use environment variables
  # AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

  # Option 3: IAM roles (recommended for production/EC2/ECS)
}

# ============================================================================
# USE DNS MODULE WITH JSON FILE
# ============================================================================

module "dns_from_json" {
  source = "../.."

  provider_type    = "aws"
  dns_config_file  = "${path.module}/dns-config.json"

  # AWS-specific configuration
  aws_region           = var.aws_region
  aws_force_destroy    = var.aws_force_destroy
  aws_delegation_set_id = var.aws_delegation_set_id

  # General options
  enable_validation = true
  default_ttl      = 300

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
    Example     = "aws-route53"
  }
}

# ============================================================================
# ALTERNATIVELY: USE TERRAFORM VARIABLES
# ============================================================================

# Uncomment this block to use variables instead of JSON
# module "dns_from_vars" {
#   source = "../.."
#
#   provider_type = "aws"
#
#   dns_zones = {
#     primary = {
#       domain  = "example.com"
#       comment = "Primary domain managed by Terraform"
#
#       records = [
#         {
#           name  = "www"
#           type  = "A"
#           value = "192.0.2.1"
#           ttl   = 300
#         },
#         {
#           name  = ""
#           type  = "A"
#           value = "192.0.2.1"
#           ttl   = 300
#         },
#         {
#           name  = "mail"
#           type  = "MX"
#           value = "mail.example.com"
#           ttl   = 300
#           priority = 10
#         },
#         {
#           name  = "cdn"
#           type  = "A"
#           value = "" # Not used in alias
#           ttl   = 300
#           alias = {
#             name                   = "d111111abcdef8.cloudfront.net"
#             zone_id                = "Z2FDTNDATAQYW2"
#             evaluate_target_health = false
#           }
#         }
#       ]
#
#       tags = {
#         Domain = "example.com"
#       }
#     }
#   }
#
#   aws_region        = var.aws_region
#   aws_force_destroy = var.aws_force_destroy
#   enable_validation = true
# }

# ============================================================================
# OUTPUTS
# ============================================================================

output "name_servers" {
  description = "Name servers to configure in your domain registrar"
  value       = module.dns_from_json.name_servers
}

output "zone_ids" {
  description = "IDs of the created Route53 zones"
  value       = module.dns_from_json.zone_ids
}

output "zones_info" {
  description = "Complete information of the zones"
  value       = module.dns_from_json.zones
}

output "next_steps" {
  description = "Next steps"
  value       = module.dns_from_json.next_steps
}
