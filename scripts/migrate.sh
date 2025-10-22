#!/bin/bash

# ============================================================================
# DNS MIGRATION HELPER
# ============================================================================
# This script helps migrate DNS configuration between providers.
#
# Flow:
#   1. Export from source provider
#   2. Validate exported configuration
#   3. Verify compatibility with destination provider
#   4. Generate Terraform configuration for the new provider
#   5. Apply changes (with confirmation)
#
# Usage:
#   ./migrate.sh --from aws --to cloudflare --domain example.com
#   ./migrate.sh --from cloudflare --to vercel --domain example.com --all
#
# ============================================================================

set -e

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FROM_PROVIDER=""
TO_PROVIDER=""
DOMAINS=()
EXPORT_ALL=false
AUTO_APPLY=false

# Help function
usage() {
    cat << EOF
Usage: $0 --from PROVIDER --to PROVIDER [OPTIONS]

Supported providers: aws, cloudflare, vercel

Options:
  --from PROVIDER         Source provider (aws, cloudflare, vercel)
  --to PROVIDER          Destination provider (aws, cloudflare, vercel)
  --domain DOMAIN        Domain to migrate (can be specified multiple times)
  --all                  Migrate all zones from the source provider
  --auto-apply           Apply changes automatically without confirmation
  -h, --help             Show this help

Examples:
  # Migrate a specific domain
  $0 --from aws --to cloudflare --domain example.com

  # Migrate multiple domains
  $0 --from aws --to cloudflare --domain example.com --domain blog.example.com

  # Migrate all zones
  $0 --from cloudflare --to vercel --all

Required environment variables:
  AWS:        AWS_PROFILE or AWS_ACCESS_KEY_ID + AWS_SECRET_ACCESS_KEY
  Cloudflare: CF_API_TOKEN
  Vercel:     VERCEL_TOKEN

EOF
    exit 1
}

# Parse arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --from)
                FROM_PROVIDER="$2"
                shift 2
                ;;
            --to)
                TO_PROVIDER="$2"
                shift 2
                ;;
            --domain)
                DOMAINS+=("$2")
                shift 2
                ;;
            --all)
                EXPORT_ALL=true
                shift
                ;;
            --auto-apply)
                AUTO_APPLY=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                echo -e "${RED}Error: Unknown argument: $1${NC}"
                usage
                ;;
        esac
    done

    # Validate arguments
    if [ -z "$FROM_PROVIDER" ] || [ -z "$TO_PROVIDER" ]; then
        echo -e "${RED}Error: You must specify --from and --to${NC}"
        usage
    fi

    if [[ ! "$FROM_PROVIDER" =~ ^(aws|cloudflare|vercel)$ ]]; then
        echo -e "${RED}Error: Invalid source provider: $FROM_PROVIDER${NC}"
        usage
    fi

    if [[ ! "$TO_PROVIDER" =~ ^(aws|cloudflare|vercel)$ ]]; then
        echo -e "${RED}Error: Invalid destination provider: $TO_PROVIDER${NC}"
        usage
    fi

    if [ "$EXPORT_ALL" = false ] && [ ${#DOMAINS[@]} -eq 0 ]; then
        echo -e "${RED}Error: You must specify --domain or --all${NC}"
        usage
    fi
}

# Print header
print_header() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       DNS MIGRATION ASSISTANT                                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
    echo -e "${BLUE}Migration: ${YELLOW}$FROM_PROVIDER${NC} → ${YELLOW}$TO_PROVIDER${NC}"
    echo ""
}

# Step 1: Export from source provider
export_from_source() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Step 1: Export from $FROM_PROVIDER${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}\n"

    local export_script="$SCRIPT_DIR/export-${FROM_PROVIDER}.sh"

    if [ ! -f "$export_script" ]; then
        echo -e "${RED}❌ Export script not found: $export_script${NC}"
        exit 1
    fi

    if [ "$EXPORT_ALL" = true ]; then
        bash "$export_script" --all
    else
        bash "$export_script" "${DOMAINS[@]}"
    fi

    echo ""
}

# Step 2: Validate exported configuration
validate_export() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Step 2: Validate exported configuration${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}\n"

    local export_file="${FROM_PROVIDER}-dns-export.json"

    if [ ! -f "$export_file" ]; then
        echo -e "${RED}❌ Export file not found: $export_file${NC}"
        exit 1
    fi

    # Validate with Python script
    if ! python3 "$SCRIPT_DIR/validate-config.py" "$export_file" --provider "$TO_PROVIDER"; then
        echo -e "${RED}❌ The exported configuration has errors${NC}"
        exit 1
    fi

    echo ""
}

# Step 3: Generate Terraform configuration
generate_terraform_config() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Step 3: Generate Terraform configuration${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}\n"

    local export_file="${FROM_PROVIDER}-dns-export.json"
    local migration_dir="migration-${FROM_PROVIDER}-to-${TO_PROVIDER}-$(date +%Y%m%d-%H%M%S)"

    mkdir -p "$migration_dir"

    # Copy DNS configuration
    cp "$export_file" "$migration_dir/dns-config.json"

    # Generate main.tf
    cat > "$migration_dir/main.tf" << EOF
# ============================================================================
# DNS MIGRATION: $FROM_PROVIDER → $TO_PROVIDER
# Generated: $(date)
# ============================================================================

terraform {
  required_version = ">= 1.3.0"
}

module "dns" {
  source = ".."

  provider_type   = "$TO_PROVIDER"
  dns_config_file = "\${path.module}/dns-config.json"

  # Provider-specific configuration
  # Uncomment and complete as needed:

EOF

    # Add destination provider-specific configuration
    case $TO_PROVIDER in
        aws)
            cat >> "$migration_dir/main.tf" << 'EOF'
  # aws_region           = "us-east-1"
  # aws_force_destroy    = false
  # aws_delegation_set_id = null
EOF
            ;;
        cloudflare)
            cat >> "$migration_dir/main.tf" << 'EOF'
  # cloudflare_account_id = "YOUR_ACCOUNT_ID"  # REQUIRED
  # cloudflare_zone_plan  = "free"
  # cloudflare_zone_type  = "full"
EOF
            ;;
        vercel)
            cat >> "$migration_dir/main.tf" << 'EOF'
  # vercel_team_id = null  # Optional
EOF
            ;;
    esac

    cat >> "$migration_dir/main.tf" << 'EOF'

  enable_validation = true
}

output "name_servers" {
  value = module.dns.name_servers
}

output "zones" {
  value = module.dns.zones
}

output "next_steps" {
  value = module.dns.next_steps
}
EOF

    # Create README
    cat > "$migration_dir/README.md" << EOF
# DNS Migration: $FROM_PROVIDER → $TO_PROVIDER

Automatically generated on $(date)

## Steps to complete the migration

### 1. Review the configuration

Review \`dns-config.json\` to ensure all records were exported correctly.

### 2. Configure credentials

EOF

    case $TO_PROVIDER in
        aws)
            cat >> "$migration_dir/README.md" << 'EOF'
```bash
export AWS_PROFILE=mi-perfil
# o
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
```
EOF
            ;;
        cloudflare)
            cat >> "$migration_dir/README.md" << 'EOF'
```bash
export TF_VAR_cloudflare_api_token="tu-api-token"
export TF_VAR_cloudflare_account_id="tu-account-id"
```
EOF
            ;;
        vercel)
            cat >> "$migration_dir/README.md" << 'EOF'
```bash
export TF_VAR_vercel_api_token="tu-api-token"
```
EOF
            ;;
    esac

    cat >> "$migration_dir/README.md" << 'EOF'

### 3. Edit main.tf

Edit `main.tf` and uncomment/complete the necessary variables.

### 4. Run Terraform

```bash
cd migration-*/
terraform init
terraform plan
terraform apply
```

### 5. Update nameservers

After applying, copy the nameservers from the output and configure them in your domain registrar.

### 6. Verify DNS propagation

```bash
dig NS your-domain.com
dig your-domain.com
```

### 7. Clean up previous provider (CAREFUL)

Only after verifying that everything works correctly can you delete the records from the previous provider.

## Rollback

If something goes wrong, you can revert the nameservers in your registrar to the previous provider.
EOF

    echo -e "${GREEN}✓ Terraform configuration generated in: $migration_dir${NC}"
    echo ""

    return 0
}

# Step 4: Confirmation and application
confirm_and_apply() {
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}Step 4: Review and Application${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}\n"

    if [ "$AUTO_APPLY" = false ]; then
        echo -e "${YELLOW}⚠️  WARNING: You are about to migrate DNS between providers.${NC}"
        echo -e "${YELLOW}   This can cause downtime if not done correctly.${NC}"
        echo ""
        echo -e "Recommendations before continuing:"
        echo "  1. Review the generated configuration"
        echo "  2. Make a backup of your current DNS records"
        echo "  3. Consider doing this during low-traffic hours"
        echo "  4. Have a rollback plan ready"
        echo ""
        read -p "Do you want to continue with automatic application? (yes/no): " -r
        echo ""

        if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
            echo -e "${YELLOW}Migration paused. Review the generated files and run Terraform manually.${NC}"
            exit 0
        fi
    fi

    echo -e "${GREEN}Continuing with the migration...${NC}"
    echo ""
}

# Main
main() {
    parse_args "$@"
    print_header

    # Execute steps
    export_from_source
    validate_export
    generate_terraform_config
    confirm_and_apply

    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ MIGRATION PREPARED                                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "📁 Configuration generated in the migration-* directory"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. cd migration-*"
    echo "  2. Review dns-config.json and main.tf"
    echo "  3. Configure credentials for the new provider"
    echo "  4. terraform init && terraform plan"
    echo "  5. terraform apply"
    echo "  6. Update nameservers in your registrar"
    echo ""
}

main "$@"
