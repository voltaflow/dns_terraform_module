# ============================================================================
# VERCEL DNS RECORDS
# ============================================================================
# Note: Vercel handles zones automatically when a domain is added.
# There is no separate "zone" resource like in AWS or Cloudflare.
# Domains are created automatically when the first record is created.

locals {
  # Get unique domains from zones
  unique_domains = distinct([
    for zone_key, zone in var.zones : zone.domain
  ])

  # Flatten all records from all zones
  all_records = flatten([
    for zone_key, zone in var.zones : [
      for idx, record in zone.records : {
        key      = "${zone_key}--${record.name}--${record.type}--${idx}"
        zone_key = zone_key
        domain   = zone.domain
        name     = record.name
        type     = record.type
        value    = record.value
        ttl      = record.ttl
        priority = record.priority
        team_id  = zone.zone_config.team_id
      }
    ]
  ])

  # Convert to map for use with for_each
  records_map = {
    for record in local.all_records :
    record.key => record
  }
}

# ============================================================================
# VERCEL DNS RECORDS
# ============================================================================
# Note: Vercel provider has strict validation for mx_priority that prevents
# conditional usage. MX priority should be included in the value field in the
# format "priority value" (e.g., "10 mail.example.com")
#
# For now, we use a single resource and omit mx_priority to avoid validation
# errors. Users should include priority in the MX record value.
# ============================================================================

resource "vercel_dns_record" "this" {
  for_each = local.records_map

  domain = each.value.domain
  name   = each.value.name
  type   = each.value.type
  # For MX records, include priority in value: "10 mail.example.com"
  value   = each.value.type == "MX" && each.value.priority != null ? "${each.value.priority} ${each.value.value}" : each.value.value
  ttl     = each.value.ttl
  team_id = each.value.team_id
}
