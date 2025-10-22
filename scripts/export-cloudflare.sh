#!/bin/bash

# ============================================================================
# EXPORT CLOUDFLARE DNS CONFIGURATION
# ============================================================================
# This script exports DNS zones and records from Cloudflare
# and converts them to the module's JSON format.
#
# Requirements:
#   - Cloudflare API Token with DNS read permissions
#   - jq installed (brew install jq / apt install jq)
#   - curl
#
# Usage:
#   export CF_API_TOKEN="your-api-token"
#   ./export-cloudflare.sh [domain1.com] [domain2.com] ...
#   ./export-cloudflare.sh --all    # Export all zones
#
# Output:
#   - cloudflare-dns-export.json
# ============================================================================

set -e

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# API Base URL
CF_API_BASE="https://api.cloudflare.com/client/v4"

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

    if [ -z "$CF_API_TOKEN" ]; then
        echo -e "${RED}❌ CF_API_TOKEN is not configured${NC}"
        echo "Run: export CF_API_TOKEN='your-api-token'"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies are installed${NC}"
}

# Call Cloudflare API
cf_api() {
    local endpoint=$1
    curl -s -X GET "$CF_API_BASE/$endpoint" \
        -H "Authorization: Bearer $CF_API_TOKEN" \
        -H "Content-Type: application/json"
}

# Get zones
get_zones() {
    if [ "$1" == "--all" ]; then
        echo -e "${YELLOW}📋 Getting all Cloudflare zones...${NC}"
        cf_api "zones" | jq '.result'
    else
        echo -e "${YELLOW}📋 Searching for specific zones...${NC}"
        local zones="["
        for domain in "$@"; do
            zone=$(cf_api "zones?name=$domain" | jq '.result[0]')
            if [ "$zone" != "null" ]; then
                if [ "$zones" != "[" ]; then
                    zones+=","
                fi
                zones+="$zone"
            fi
        done
        zones+="]"
        echo "$zones"
    fi
}

# Export zone records
export_zone_records() {
    local zone_id=$1
    local zone_name=$2

    echo -e "${YELLOW}  📝 Exporting records for $zone_name...${NC}"

    cf_api "zones/$zone_id/dns_records?per_page=1000" | jq '.result'
}

# Convert Cloudflare records to module format
convert_records() {
    local records=$1

    echo "$records" | jq '[.[] | {
        name: (if .name == .zone_name then "" else (.name | sub("\\." + .zone_name + "$"; "")) end),
        type: .type,
        value: .content,
        ttl: (if .proxied then 1 else .ttl end),
        priority: .priority,
        proxied: .proxied
    } | del(.priority | select(. == null))]'
}

# Main
main() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       CLOUDFLARE DNS EXPORT                                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_dependencies

    if [ $# -eq 0 ]; then
        echo "Usage: $0 [domain1.com] [domain2.com] ..."
        echo "       $0 --all"
        exit 1
    fi

    zones=$(get_zones "$@")
    zone_count=$(echo "$zones" | jq length)

    echo -e "${GREEN}✓ Found $zone_count zones${NC}"
    echo ""

    # Create JSON object for the module
    config="{"
    first=true

    echo "$zones" | jq -c '.[]' | while read -r zone; do
        zone_id=$(echo "$zone" | jq -r '.id')
        zone_name=$(echo "$zone" | jq -r '.name')
        zone_key=$(echo "$zone_name" | sed 's/\./_/g')

        echo -e "${YELLOW}🔄 Processing zone: $zone_name${NC}"

        # Get records
        records=$(export_zone_records "$zone_id" "$zone_name")
        converted_records=$(convert_records "$records")

        # Add to config
        if [ "$first" = true ]; then
            first=false
        else
            config+=","
        fi

        config+="\"$zone_key\":{\"domain\":\"$zone_name\",\"records\":$converted_records}"
    done

    config+="}"

    # Save file
    output_file="cloudflare-dns-export.json"
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
