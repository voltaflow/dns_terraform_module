# ============================================================================
# DNS CONFIGURATION LOADING AND NORMALIZATION
# ============================================================================

locals {
  # Load configuration from JSON file or use variables
  dns_config_raw = var.dns_config_file != null ? jsondecode(file(var.dns_config_file)) : var.dns_zones

  # Normalize DNS zone structure
  dns_zones_normalized = {
    for zone_key, zone_config in local.dns_config_raw : zone_key => {
      domain  = zone_config.domain
      comment = try(zone_config.comment, "Managed by Terraform")
      tags    = merge(var.tags, try(zone_config.tags, {}))

      # Normalize DNS records
      records = [
        for record in zone_config.records : {
          name     = record.name
          type     = upper(record.type)
          value    = record.value
          ttl      = try(record.ttl, var.default_ttl)
          priority = try(record.priority, null)

          # Provider-specific features
          proxied = try(record.proxied, false)
          alias   = try(record.alias, null)
        }
      ]
    }
  }

  # ============================================================================
  # PROVIDER COMPATIBILITY VALIDATION
  # ============================================================================

  # Record types supported by each provider
  provider_supported_types = {
    aws = [
      "A", "AAAA", "CAA", "CNAME", "MX", "NAPTR", "NS",
      "PTR", "SOA", "SPF", "SRV", "TXT"
    ]
    cloudflare = [
      "A", "AAAA", "CAA", "CNAME", "HTTPS", "TXT", "SRV",
      "LOC", "MX", "NS", "CERT", "DNSKEY", "DS", "NAPTR",
      "SMIMEA", "SSHFP", "SVCB", "TLSA", "URI"
    ]
    vercel = [
      "A", "AAAA", "ALIAS", "CAA", "CNAME", "MX", "SRV", "TXT"
    ]
  }

  # Validate record types with selected provider
  unsupported_records = var.enable_validation ? flatten([
    for zone_key, zone in local.dns_zones_normalized : [
      for record in zone.records : {
        zone   = zone_key
        record = record.name
        type   = record.type
      } if !contains(local.provider_supported_types[var.provider_type], record.type)
    ]
  ]) : []

  # Warning message for unsupported records
  validation_warnings = length(local.unsupported_records) > 0 ? join("\n", concat([
    "⚠️  WARNING: The following records are not supported by ${var.provider_type}:"
    ], [
    for rec in local.unsupported_records :
    "   - ${rec.zone}/${rec.record} (type: ${rec.type})"
  ])) : ""

  # ============================================================================
  # PROVIDER-SPECIFIC TRANSFORMATIONS
  # ============================================================================

  # For AWS Route53: group records by zone
  aws_zones = {
    for zone_key, zone in local.dns_zones_normalized : zone_key => {
      domain  = zone.domain
      comment = zone.comment
      tags    = zone.tags
      records = zone.records
      zone_config = {
        force_destroy     = var.aws_force_destroy
        delegation_set_id = var.aws_delegation_set_id
      }
    }
  }

  # For Cloudflare: include plan and type configuration
  cloudflare_zones = {
    for zone_key, zone in local.dns_zones_normalized : zone_key => {
      domain  = zone.domain
      records = zone.records
      zone_config = {
        account_id = var.cloudflare_account_id
        plan       = var.cloudflare_zone_plan
        type       = var.cloudflare_zone_type
      }
    }
  }

  # For Vercel: simplify structure
  vercel_zones = {
    for zone_key, zone in local.dns_zones_normalized : zone_key => {
      domain  = zone.domain
      records = zone.records
      zone_config = {
        team_id = var.vercel_team_id
      }
    }
  }

  # ============================================================================
  # METADATA AND DEBUGGING
  # ============================================================================

  module_metadata = {
    provider                = var.provider_type
    zones_count             = length(local.dns_zones_normalized)
    total_records           = sum([for z in local.dns_zones_normalized : length(z.records)])
    has_validation_warnings = length(local.unsupported_records) > 0
  }
}

# Validation that fails if there are unsupported records and validation is enabled
resource "null_resource" "validation_check" {
  count = var.enable_validation && length(local.unsupported_records) > 0 ? 1 : 0

  triggers = {
    validation_error = "There are unsupported records for ${var.provider_type}. Check logs or disable enable_validation."
  }

  lifecycle {
    precondition {
      condition     = length(local.unsupported_records) == 0
      error_message = local.validation_warnings
    }
  }
}
