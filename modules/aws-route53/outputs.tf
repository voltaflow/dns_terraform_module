output "zone_ids" {
  description = "IDs of the created Route53 zones"
  value = {
    for k, zone in aws_route53_zone.this :
    k => zone.zone_id
  }
}

output "name_servers" {
  description = "Name servers of the Route53 zones"
  value = {
    for k, zone in aws_route53_zone.this :
    k => zone.name_servers
  }
}

output "zones" {
  description = "Complete information of the created zones"
  value = {
    for k, zone in aws_route53_zone.this :
    k => {
      zone_id      = zone.zone_id
      name_servers = zone.name_servers
      domain       = zone.name
      arn          = zone.arn
    }
  }
}

output "record_fqdns" {
  description = "FQDNs of all created records"
  value = merge(
    {
      for k, record in aws_route53_record.standard :
      k => record.fqdn
    },
    {
      for k, record in aws_route53_record.alias :
      k => record.fqdn
    }
  )
}
