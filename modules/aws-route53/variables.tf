variable "zones" {
  description = "DNS zone configuration for AWS Route53"
  type = map(object({
    domain  = string
    comment = string
    tags    = map(string)
    records = list(object({
      name     = string
      type     = string
      value    = string
      ttl      = number
      priority = optional(number)
      alias = optional(object({
        name                   = string
        zone_id                = string
        evaluate_target_health = bool
      }))
    }))
    zone_config = object({
      force_destroy     = bool
      delegation_set_id = optional(string)
    })
  }))
}
