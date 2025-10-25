# ============================================================================
# BASIC USAGE EXAMPLE
# ============================================================================
# This example shows the most common way to use the DNS module with a JSON
# configuration file. This approach is recommended for most use cases.
# ============================================================================

module "dns" {
  source = "github.com/voltaflow/dns_terraform_module"

  # Required: Choose your DNS provider
  provider_type = "cloudflare" # Options: "aws", "cloudflare", "vercel"

  # Option 1: Use JSON file for configuration (recommended)
  dns_config_file = "${path.module}/dns-config.json"

  # Provider-specific configuration
  # For Cloudflare (required):
  cloudflare_account_id = var.cloudflare_account_id

  # For AWS Route53 (optional):
  # aws_region = "us-east-1"

  # For Vercel (optional):
  # vercel_team_id = "team_xxxxx"

  # Optional: Enable validation (recommended)
  enable_validation = true

  # Optional: Set default TTL
  default_ttl = 300

  # Optional: Add tags (AWS/Cloudflare only)
  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "name_servers" {
  description = "Name servers to configure at your domain registrar"
  value       = module.dns.name_servers
}

output "zone_ids" {
  description = "IDs of created DNS zones"
  value       = module.dns.zone_ids
}

output "next_steps" {
  description = "Post-deployment instructions"
  value       = module.dns.next_steps
}
