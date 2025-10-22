# ============================================================================
# DNS TERRAFORM MODULE - MULTI-PROVIDER
# ============================================================================
# This module allows managing DNS zones and records across multiple providers:
# - AWS Route53
# - Cloudflare
# - Vercel
#
# Supports configuration via JSON file or Terraform variables.
# ============================================================================

# ============================================================================
# AWS ROUTE53 MODULE
# ============================================================================

module "aws_route53" {
  count  = var.provider_type == "aws" ? 1 : 0
  source = "./modules/aws-route53"

  zones = local.aws_zones
}

# ============================================================================
# CLOUDFLARE MODULE
# ============================================================================

module "cloudflare" {
  count  = var.provider_type == "cloudflare" ? 1 : 0
  source = "./modules/cloudflare"

  zones = local.cloudflare_zones
}

# ============================================================================
# VERCEL MODULE
# ============================================================================

module "vercel" {
  count  = var.provider_type == "vercel" ? 1 : 0
  source = "./modules/vercel"

  zones = local.vercel_zones
}

# ============================================================================
# INFORMATION AND DEBUGGING
# ============================================================================

# Metadata output for debugging
resource "terraform_data" "module_info" {
  input = {
    provider         = var.provider_type
    zones_count      = local.module_metadata.zones_count
    total_records    = local.module_metadata.total_records
    config_source    = var.dns_config_file != null ? "JSON file" : "Terraform variables"
    validation_enabled = var.enable_validation
    has_warnings     = local.module_metadata.has_validation_warnings
  }

  lifecycle {
    precondition {
      condition     = var.provider_type == "cloudflare" ? var.cloudflare_account_id != null : true
      error_message = "cloudflare_account_id is required when provider_type is 'cloudflare'."
    }

    precondition {
      condition     = length(local.dns_zones_normalized) > 0
      error_message = "You must provide at least one DNS zone via dns_config_file or dns_zones."
    }
  }
}
