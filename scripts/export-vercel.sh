#!/bin/bash

# ============================================================================
# EXPORT VERCEL DNS CONFIGURATION
# ============================================================================
# This script exports DNS records from Vercel
# and converts them to the module's JSON format.
#
# Requirements:
#   - Vercel API Token
#   - jq installed (brew install jq / apt install jq)
#   - curl
#
# Usage:
#   export VERCEL_TOKEN="your-api-token"
#   ./export-vercel.sh domain1.com [domain2.com] ...
#
# Output:
#   - vercel-dns-export.json
# ============================================================================

set -e

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# API Base URL
VERCEL_API_BASE="https://api.vercel.com"

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is not installed${NC}"
        exit 1
    fi

    if ! command -v curl &> /dev/null; then
        echo -e "${RED}❌ curl is not installed${NC}"
        exit 1
    fi

    if [ -z "$VERCEL_TOKEN" ]; then
        echo -e "${RED}❌ VERCEL_TOKEN is not configured${NC}"
        echo "Run: export VERCEL_TOKEN='your-api-token'"
        echo "Get token at: https://vercel.com/account/tokens"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies are installed${NC}"
}

# Call Vercel API
vercel_api() {
    local endpoint=$1
    curl -s -X GET "$VERCEL_API_BASE/$endpoint" \
        -H "Authorization: Bearer $VERCEL_TOKEN" \
        -H "Content-Type: application/json"
}

# Export domain records
export_domain_records() {
    local domain=$1

    echo -e "${YELLOW}  📝 Exporting records for $domain...${NC}"

    vercel_api "v4/domains/$domain/records" | jq '.records'
}

# Convert Vercel records to module format
convert_records() {
    local records=$1

    echo "$records" | jq '[.[] | {
        name: .name,
        type: .type,
        value: .value,
        ttl: (.ttl // 60),
        priority: (if .mxPriority then .mxPriority else null end)
    } | del(.priority | select(. == null))]'
}

# Main
main() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       VERCEL DNS EXPORT                                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_dependencies

    if [ $# -eq 0 ]; then
        echo "Usage: $0 domain1.com [domain2.com] ..."
        exit 1
    fi

    echo -e "${GREEN}✓ Processing $# domains${NC}"
    echo ""

    # Create JSON object for the module
    config="{"
    first=true

    for domain in "$@"; do
        zone_key=$(echo "$domain" | sed 's/\./_/g')

        echo -e "${YELLOW}🔄 Processing domain: $domain${NC}"

        # Get records
        records=$(export_domain_records "$domain")

        if [ "$records" == "null" ] || [ -z "$records" ]; then
            echo -e "${RED}  ⚠️  No records found for $domain${NC}"
            continue
        fi

        converted_records=$(convert_records "$records")

        # Add to config
        if [ "$first" = true ]; then
            first=false
        else
            config+=","
        fi

        config+="\"$zone_key\":{\"domain\":\"$domain\",\"records\":$converted_records}"
    done

    config+="}"

    # Save file
    output_file="vercel-dns-export.json"
    echo "$config" | jq '.' > "$output_file"

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ EXPORT COMPLETED                                           ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "📄 Generated file: ${GREEN}$output_file${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Review the generated file: cat $output_file"
    echo "  2. Validate the file: ./scripts/validate-config.py $output_file"
    echo "  3. Use in the module: dns_config_file = \"$output_file\""
}

main "$@"
