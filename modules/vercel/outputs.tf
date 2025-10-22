output "domains" {
  description = "Domains managed in Vercel"
  value       = local.unique_domains
}

output "zones" {
  description = "Zone information (Vercel does not have a separate zone_id concept)"
  value = {
    for zone_key, zone in var.zones :
    zone_key => {
      domain = zone.domain
      # Vercel does not provide nameservers directly via Terraform
      # They must be queried via Vercel Dashboard or API
    }
  }
}

output "records" {
  description = "Information about all created records"
  value = {
    for k, record in vercel_dns_record.this :
    k => {
      id     = record.id
      domain = record.domain
      name   = record.name
      type   = record.type
      value  = record.value
    }
  }
}

output "record_ids" {
  description = "IDs of all DNS records in Vercel"
  value = {
    for k, record in vercel_dns_record.this :
    k => record.id
  }
}
