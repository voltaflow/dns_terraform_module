# ============================================================================
# TFLINT CONFIGURATION
# ============================================================================
# TFLint configuration for Terraform code linting
# ============================================================================

config {
  # Enable module inspection
  module = true

  # Force provider installation
  force = false

  # Disable color output
  disabled_by_default = false
}

# AWS Plugin
plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Terraform Plugin (best practices)
plugin "terraform" {
  enabled = true
  version = "0.8.0"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"

  preset = "recommended"
}

# ============================================================================
# RULES
# ============================================================================

# Terraform naming conventions
rule "terraform_naming_convention" {
  enabled = true

  # Variables
  variable {
    format = "snake_case"
  }

  # Outputs
  output {
    format = "snake_case"
  }

  # Resources
  resource {
    format = "snake_case"
  }

  # Modules
  module {
    format = "snake_case"
  }

  # Locals
  locals {
    format = "snake_case"
  }
}

# Require variable descriptions
rule "terraform_documented_variables" {
  enabled = true
}

# Require output descriptions
rule "terraform_documented_outputs" {
  enabled = true
}

# Terraform standard module structure
rule "terraform_standard_module_structure" {
  enabled = true
}

# Require type constraints for variables
rule "terraform_typed_variables" {
  enabled = true
}

# Unused declarations
rule "terraform_unused_declarations" {
  enabled = true
}

# Deprecated syntax
rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

# Comment syntax
rule "terraform_comment_syntax" {
  enabled = true
}

# Workspace remote
rule "terraform_workspace_remote" {
  enabled = true
}

# Required providers
rule "terraform_required_providers" {
  enabled = true
}

# Required version
rule "terraform_required_version" {
  enabled = true
}
