# ============================================================================
# CLOUDFLARE ZONES
# ============================================================================

resource "cloudflare_zone" "this" {
  for_each = var.zones

  account_id = each.value.zone_config.account_id
  zone       = each.value.domain
  plan       = each.value.zone_config.plan
  type       = each.value.zone_config.type
}

# ============================================================================
# CLOUDFLARE DNS RECORDS
# ============================================================================

locals {
  # Flatten all records from all zones
  all_records = flatten([
    for zone_key, zone in var.zones : [
      for idx, record in zone.records : {
        key      = "${zone_key}--${record.name}--${record.type}--${idx}"
        zone_key = zone_key
        zone_id  = cloudflare_zone.this[zone_key].id
        name     = record.name
        type     = record.type
        value    = record.value
        ttl      = record.ttl
        priority = record.priority
        proxied  = record.proxied
      }
    ]
  ])

  # Convert to map for use with for_each
  records_map = {
    for record in local.all_records :
    record.key => record
  }
}

resource "cloudflare_record" "this" {
  for_each = local.records_map

  zone_id  = each.value.zone_id
  name     = each.value.name
  type     = each.value.type
  value    = each.value.value
  ttl      = each.value.proxied ? 1 : each.value.ttl  # TTL must be 1 if proxied
  priority = each.value.priority

  # Proxy only works with A, AAAA and CNAME
  proxied = contains(["A", "AAAA", "CNAME"], each.value.type) ? each.value.proxied : false

  # Allow overwriting existing records during import
  allow_overwrite = true
}
