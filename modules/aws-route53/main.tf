# ============================================================================
# AWS ROUTE53 HOSTED ZONES
# ============================================================================

resource "aws_route53_zone" "this" {
  for_each = var.zones

  name              = each.value.domain
  comment           = each.value.comment
  delegation_set_id = each.value.zone_config.delegation_set_id
  force_destroy     = each.value.zone_config.force_destroy

  tags = merge(
    each.value.tags,
    {
      Name = each.value.domain
    }
  )
}

# ============================================================================
# AWS ROUTE53 DNS RECORDS
# ============================================================================

# Create a flat map of all records to use with for_each
locals {
  # Flatten all records from all zones
  all_records = flatten([
    for zone_key, zone in var.zones : [
      for idx, record in zone.records : {
        key          = "${zone_key}--${record.name}--${record.type}--${idx}"
        zone_key     = zone_key
        zone_id      = aws_route53_zone.this[zone_key].zone_id
        name         = record.name
        type         = record.type
        value        = record.value
        ttl          = record.ttl
        priority     = record.priority
        alias        = record.alias
        is_alias     = record.alias != null
      }
    ]
  ])

  # Convert to map for use with for_each
  records_map = {
    for record in local.all_records :
    record.key => record
  }

  # Separate standard records from alias records
  standard_records = {
    for k, v in local.records_map :
    k => v if !v.is_alias
  }

  alias_records = {
    for k, v in local.records_map :
    k => v if v.is_alias
  }
}

# Standard DNS records (non-alias)
resource "aws_route53_record" "standard" {
  for_each = local.standard_records

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = each.value.ttl

  # For MX records, the value must include the priority
  records = each.value.type == "MX" && each.value.priority != null ? [
    "${each.value.priority} ${each.value.value}"
  ] : [each.value.value]

  # Allow overwriting automatically created NS and SOA records
  allow_overwrite = contains(["NS", "SOA"], each.value.type)
}

# Alias records (AWS-specific)
resource "aws_route53_record" "alias" {
  for_each = local.alias_records

  zone_id = each.value.zone_id
  name    = each.value.name
  type    = each.value.type

  alias {
    name                   = each.value.alias.name
    zone_id                = each.value.alias.zone_id
    evaluate_target_health = each.value.alias.evaluate_target_health
  }
}
