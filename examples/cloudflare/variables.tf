variable "cloudflare_api_token" {
  description = "Cloudflare API Token (obtain at: https://dash.cloudflare.com/profile/api-tokens)"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (REQUIRED)"
  type        = string
}

variable "cloudflare_zone_plan" {
  description = "Cloudflare plan for the zones"
  type        = string
  default     = "free"
}

variable "cloudflare_zone_type" {
  description = "Cloudflare zone type"
  type        = string
  default     = "full"
}
