output "zone_ids" {
  description = "IDs of the created Cloudflare zones"
  value = {
    for k, zone in cloudflare_zone.this :
    k => zone.id
  }
}

output "name_servers" {
  description = "Name servers of the Cloudflare zones"
  value = {
    for k, zone in cloudflare_zone.this :
    k => zone.name_servers
  }
}

output "zones" {
  description = "Complete information of the created zones"
  value = {
    for k, zone in cloudflare_zone.this :
    k => {
      zone_id          = zone.id
      name_servers     = zone.name_servers
      domain           = zone.name
      status           = zone.status
      verification_key = zone.verification_key
    }
  }
}

output "record_hostnames" {
  description = "Hostnames of all created records"
  value = {
    for k, record in cloudflare_dns_record.this :
    k => record.hostname
  }
}

output "proxied_records" {
  description = "Records that are using Cloudflare proxy"
  value = {
    for k, record in cloudflare_dns_record.this :
    k => record.proxied
    if record.proxied
  }
}
