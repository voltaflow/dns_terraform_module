variable "vercel_api_token" {
  description = "Vercel API Token (get at: https://vercel.com/account/tokens)"
  type        = string
  sensitive   = true
}

variable "vercel_team_id" {
  description = "Vercel team ID (optional, for team accounts)"
  type        = string
  default     = null
}
