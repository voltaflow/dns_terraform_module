# ============================================================================
# PROVIDER CONFIGURATION
# ============================================================================

variable "provider_type" {
  description = "DNS provider to use: 'aws', 'cloudflare', or 'vercel'"
  type        = string
  validation {
    condition     = contains(["aws", "cloudflare", "vercel"], var.provider_type)
    error_message = "provider_type must be 'aws', 'cloudflare', or 'vercel'."
  }
}

# ============================================================================
# DNS CONFIGURATION INPUT (DUAL: JSON OR VARIABLES)
# ============================================================================

variable "dns_config_file" {
  description = "Path to JSON file with DNS zone configuration. Takes priority over dns_zones if provided"
  type        = string
  default     = null
}

variable "dns_zones" {
  description = "DNS zone configuration using Terraform variables. Ignored if dns_config_file is defined"
  type = map(object({
    domain = string
    records = list(object({
      name    = string
      type    = string
      value   = string
      ttl     = optional(number, 300)
      priority = optional(number)

      # Provider-specific features
      proxied = optional(bool, false)  # Cloudflare proxy mode
      alias   = optional(object({       # AWS Route53 alias records
        name                   = string
        zone_id               = string
        evaluate_target_health = optional(bool, false)
      }))
    }))

    # Additional zone configuration
    comment = optional(string, "Managed by Terraform")
    tags    = optional(map(string), {})
  }))
  default = {}
}

# ============================================================================
# AWS ROUTE53 CONFIGURATION
# ============================================================================

variable "aws_region" {
  description = "AWS region for Route53 (used only with AWS provider)"
  type        = string
  default     = "us-east-1"
}

variable "aws_delegation_set_id" {
  description = "Route53 delegation set ID to reuse nameservers (optional)"
  type        = string
  default     = null
}

variable "aws_force_destroy" {
  description = "Allow destroying Route53 zones even if they contain records"
  type        = bool
  default     = false
}

# ============================================================================
# CLOUDFLARE CONFIGURATION
# ============================================================================

variable "cloudflare_account_id" {
  description = "Cloudflare account ID (required for cloudflare provider)"
  type        = string
  default     = null
}

variable "cloudflare_zone_plan" {
  description = "Cloudflare plan for new zones: 'free', 'pro', 'business', 'enterprise'"
  type        = string
  default     = "free"
  validation {
    condition     = contains(["free", "pro", "business", "enterprise"], var.cloudflare_zone_plan)
    error_message = "cloudflare_zone_plan must be 'free', 'pro', 'business', or 'enterprise'."
  }
}

variable "cloudflare_zone_type" {
  description = "Cloudflare zone type: 'full' or 'partial'"
  type        = string
  default     = "full"
  validation {
    condition     = contains(["full", "partial"], var.cloudflare_zone_type)
    error_message = "cloudflare_zone_type must be 'full' or 'partial'."
  }
}

# ============================================================================
# VERCEL CONFIGURATION
# ============================================================================

variable "vercel_team_id" {
  description = "Vercel team ID (optional, for team zones)"
  type        = string
  default     = null
}

# ============================================================================
# GENERAL OPTIONS
# ============================================================================

variable "enable_validation" {
  description = "Enable record compatibility validation with selected provider"
  type        = bool
  default     = true
}

variable "default_ttl" {
  description = "Default TTL for DNS records (in seconds)"
  type        = number
  default     = 300
  validation {
    condition     = var.default_ttl >= 60 && var.default_ttl <= 86400
    error_message = "default_ttl must be between 60 (1 minute) and 86400 (24 hours)."
  }
}

variable "tags" {
  description = "Default tags to apply to all resources (when provider supports it)"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Module    = "dns-terraform-module"
  }
}
