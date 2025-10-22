# ============================================================================
# DNS MULTI-PROVIDER MODULE OUTPUTS
# ============================================================================

# ============================================================================
# MAIN OUTPUTS
# ============================================================================

output "provider" {
  description = "DNS provider used"
  value       = var.provider_type
}

output "zone_ids" {
  description = "IDs of the created DNS zones (format varies by provider)"
  value = var.provider_type == "aws" ? (
    length(module.aws_route53) > 0 ? module.aws_route53[0].zone_ids : {}
    ) : var.provider_type == "cloudflare" ? (
    length(module.cloudflare) > 0 ? module.cloudflare[0].zone_ids : {}
    ) : var.provider_type == "vercel" ? (
    {} # Vercel does not have separate zone_ids
  ) : {}
}

output "name_servers" {
  description = "Name servers for the DNS zones (must be configured in the domain registrar)"
  value = var.provider_type == "aws" ? (
    length(module.aws_route53) > 0 ? module.aws_route53[0].name_servers : {}
    ) : var.provider_type == "cloudflare" ? (
    length(module.cloudflare) > 0 ? module.cloudflare[0].name_servers : {}
    ) : var.provider_type == "vercel" ? (
    {} # Vercel nameservers must be consulted via dashboard
  ) : {}
}

output "zones" {
  description = "Detailed information of all created zones"
  value = var.provider_type == "aws" ? (
    length(module.aws_route53) > 0 ? module.aws_route53[0].zones : {}
    ) : var.provider_type == "cloudflare" ? (
    length(module.cloudflare) > 0 ? module.cloudflare[0].zones : {}
    ) : var.provider_type == "vercel" ? (
    length(module.vercel) > 0 ? module.vercel[0].zones : {}
  ) : {}
}

# ============================================================================
# PROVIDER-SPECIFIC OUTPUTS
# ============================================================================

output "aws_record_fqdns" {
  description = "FQDNs of AWS Route53 records (only available when provider_type=aws)"
  value       = var.provider_type == "aws" && length(module.aws_route53) > 0 ? module.aws_route53[0].record_fqdns : null
}

output "cloudflare_proxied_records" {
  description = "Records with Cloudflare proxy enabled (only available when provider_type=cloudflare)"
  value       = var.provider_type == "cloudflare" && length(module.cloudflare) > 0 ? module.cloudflare[0].proxied_records : null
}

output "vercel_record_ids" {
  description = "Vercel record IDs (only available when provider_type=vercel)"
  value       = var.provider_type == "vercel" && length(module.vercel) > 0 ? module.vercel[0].record_ids : null
}

# ============================================================================
# METADATA AND DEBUGGING
# ============================================================================

output "module_info" {
  description = "Module information and statistics"
  value = {
    provider          = var.provider_type
    zones_count       = local.module_metadata.zones_count
    total_records     = local.module_metadata.total_records
    config_source     = var.dns_config_file != null ? "JSON file: ${var.dns_config_file}" : "Terraform variables"
    validation_enabled = var.enable_validation
    has_warnings      = local.module_metadata.has_validation_warnings
  }
}

output "validation_warnings" {
  description = "Record compatibility validation warnings (if any)"
  value       = local.validation_warnings != "" ? local.validation_warnings : "✓ No warnings"
}

# ============================================================================
# POST-DEPLOYMENT INSTRUCTIONS
# ============================================================================

output "next_steps" {
  description = "Next steps after deployment"
  value = var.provider_type == "aws" ? (
    length(module.aws_route53) > 0 ? format(
      "\n\n╔════════════════════════════════════════════════════════════════╗\n║  NEXT STEPS - AWS Route53                                      ║\n╚════════════════════════════════════════════════════════════════╝\n\n1. Configure the nameservers in your domain registrar:\n%s\n\n2. Verify DNS propagation:\n   dig NS %s\n\n3. Validate that records resolve correctly:\n   dig %s\n",
      join("\n", [
        for zone_key, ns in module.aws_route53[0].name_servers :
        "   ${zone_key}: ${join(", ", ns)}"
      ]),
      try(values(local.dns_zones_normalized)[0].domain, "your-domain.com"),
      try(values(local.dns_zones_normalized)[0].domain, "your-domain.com")
    ) : ""
    ) : var.provider_type == "cloudflare" ? (
    length(module.cloudflare) > 0 ? format(
      "\n\n╔════════════════════════════════════════════════════════════════╗\n║  NEXT STEPS - Cloudflare                                       ║\n╚════════════════════════════════════════════════════════════════╝\n\n1. Configure the nameservers in your registrar:\n%s\n\n2. Verify the zone status in Cloudflare Dashboard\n\n3. Wait for the status to change to 'active' (may take up to 24h)\n\n4. Configure additional options in Cloudflare:\n   - SSL/TLS settings\n   - Page Rules\n   - Firewall Rules\n",
      join("\n", [
        for zone_key, ns in module.cloudflare[0].name_servers :
        "   ${zone_key}: ${join(", ", ns)}"
      ])
    ) : ""
    ) : var.provider_type == "vercel" ? (
    "\n\n╔════════════════════════════════════════════════════════════════╗\n║  NEXT STEPS - Vercel                                           ║\n╚════════════════════════════════════════════════════════════════╝\n\n1. Go to Vercel Dashboard: https://vercel.com/dashboard\n\n2. Find your domain in the 'Domains' section\n\n3. Copy the nameservers that Vercel provides\n\n4. Configure those nameservers in your domain registrar\n\n5. Verify the domain in Vercel Dashboard\n"
  ) : ""
}
