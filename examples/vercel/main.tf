# ============================================================================
# EXAMPLE: VERCEL
# ============================================================================
# This example shows how to use the DNS module with Vercel.
# Ideal for projects deployed on Vercel that need DNS.
# ============================================================================

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = ">= 1.0.0"
    }
  }
}

# Configure Vercel provider
provider "vercel" {
  api_token = var.vercel_api_token
  team      = var.vercel_team_id  # Optional, for teams
}

# ============================================================================
# USE DNS MODULE WITH JSON FILE
# ============================================================================

module "dns_from_json" {
  source = "../.."

  provider_type   = "vercel"
  dns_config_file = "${path.module}/dns-config.json"

  # Vercel specific configuration (optional)
  vercel_team_id = var.vercel_team_id

  # General options
  enable_validation = true
  default_ttl      = 60

  tags = {
    Environment = "example"
    ManagedBy   = "Terraform"
    Example     = "vercel"
  }
}

# ============================================================================
# ALTERNATIVELY: USE TERRAFORM VARIABLES
# ============================================================================

# Uncomment this block to use variables instead of JSON
# module "dns_from_vars" {
#   source = "../.."
#
#   provider_type = "vercel"
#
#   dns_zones = {
#     primary = {
#       domain  = "example.com"
#
#       records = [
#         {
#           name  = ""
#           type  = "A"
#           value = "76.76.21.21"  # Vercel IP
#           ttl   = 60
#         },
#         {
#           name  = "www"
#           type  = "CNAME"
#           value = "cname.vercel-dns.com"
#           ttl   = 60
#         },
#         {
#           name  = ""
#           type  = "MX"
#           value = "mail.example.com"
#           ttl   = 300
#           priority = 10
#         }
#       ]
#     }
#   }
#
#   vercel_team_id    = var.vercel_team_id
#   enable_validation = true
# }

# ============================================================================
# OUTPUTS
# ============================================================================

output "domains" {
  description = "Managed domains in Vercel"
  value       = module.dns_from_json.zones
}

output "records" {
  description = "DNS record IDs in Vercel"
  value       = module.dns_from_json.vercel_record_ids
}

output "next_steps" {
  description = "Next steps"
  value       = module.dns_from_json.next_steps
}
