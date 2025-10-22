variable "zones" {
  description = "DNS zone configuration for Vercel"
  type = map(object({
    domain = string
    records = list(object({
      name     = string
      type     = string
      value    = string
      ttl      = number
      priority = optional(number)
    }))
    zone_config = object({
      team_id = optional(string)
    })
  }))
}
