# ============================================================================
# EXAMPLE: CLOUDFLARE
# ============================================================================
# This example demonstrates how to use the DNS module with Cloudflare.
# Includes features such as proxy mode and multiple record types.
# ============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.0.0"
    }
  }
}

# Configure Cloudflare provider
provider "cloudflare" {
  api_token = var.cloudflare_api_token

  # Or use legacy method (not recommended):
  # email   = var.cloudflare_email
  # api_key = var.cloudflare_api_key
}

# ============================================================================
# USE DNS MODULE WITH JSON FILE
# ============================================================================

module "dns_from_json" {
  source = "../.."

  provider_type   = "cloudflare"
  dns_config_file = "${path.module}/dns-config.json"

  # Cloudflare-specific configuration (REQUIRED)
  cloudflare_account_id = var.cloudflare_account_id
  cloudflare_zone_plan  = var.cloudflare_zone_plan
  cloudflare_zone_type  = var.cloudflare_zone_type

  # General options
  enable_validation = true
  default_ttl       = 300

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
    Example     = "cloudflare"
  }
}

# ============================================================================
# ALTERNATIVELY: USE TERRAFORM VARIABLES
# ============================================================================

# Uncomment this block to use variables instead of JSON
# module "dns_from_vars" {
#   source = "../.."
#
#   provider_type = "cloudflare"
#
#   dns_zones = {
#     primary = {
#       domain  = "example.com"
#
#       records = [
#         {
#           name    = "www"
#           type    = "A"
#           value   = "192.0.2.1"
#           ttl     = 1
#           proxied = true  # Cloudflare proxy enabled
#         },
#         {
#           name    = ""
#           type    = "A"
#           value   = "192.0.2.1"
#           ttl     = 1
#           proxied = true
#         },
#         {
#           name    = "direct"
#           type    = "A"
#           value   = "192.0.2.50"
#           ttl     = 300
#           proxied = false  # No proxy, DNS only
#         },
#         {
#           name    = ""
#           type    = "MX"
#           value   = "mail.example.com"
#           ttl     = 300
#           priority = 10
#         }
#       ]
#     }
#   }
#
#   cloudflare_account_id = var.cloudflare_account_id
#   cloudflare_zone_plan  = var.cloudflare_zone_plan
#   enable_validation     = true
# }

# ============================================================================
# OUTPUTS
# ============================================================================

output "name_servers" {
  description = "Name servers to configure in your domain registrar"
  value       = module.dns_from_json.name_servers
}

output "zone_ids" {
  description = "IDs of the Cloudflare zones created"
  value       = module.dns_from_json.zone_ids
}

output "zones_info" {
  description = "Complete information of the zones"
  value       = module.dns_from_json.zones
}

output "proxied_records" {
  description = "Records with Cloudflare proxy enabled"
  value       = module.dns_from_json.cloudflare_proxied_records
}

output "next_steps" {
  description = "Next steps"
  value       = module.dns_from_json.next_steps
}
