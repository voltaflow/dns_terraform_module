variable "aws_region" {
  description = "AWS region for Route53"
  type        = string
  default     = "us-east-1"
}

variable "aws_force_destroy" {
  description = "Allow destroying zones even if they contain records"
  type        = bool
  default     = false
}

variable "aws_delegation_set_id" {
  description = "ID of the delegation set to reuse nameservers (optional)"
  type        = string
  default     = null
}
