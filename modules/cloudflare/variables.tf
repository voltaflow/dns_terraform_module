variable "zones" {
  description = "DNS zone configuration for Cloudflare"
  type = map(object({
    domain = string
    records = list(object({
      name     = string
      type     = string
      value    = string
      ttl      = number
      priority = optional(number)
      proxied  = bool
    }))
    zone_config = object({
      account_id = string
      plan       = string
      type       = string
    })
  }))
}
