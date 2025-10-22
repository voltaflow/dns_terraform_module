#!/bin/bash

# ============================================================================
# EXPORT AWS ROUTE53 DNS CONFIGURATION
# ============================================================================
# This script exports DNS zones and records from AWS Route53
# and converts them to the module's JSON format.
#
# Requirements:
#   - AWS CLI configured with credentials
#   - jq installed (brew install jq / apt install jq)
#
# Usage:
#   ./export-aws.sh [domain1.com] [domain2.com] ...
#   ./export-aws.sh --all    # Export all zones
#
# Output:
#   - aws-dns-export.json
# ============================================================================

set -e

# Colours for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Colour

# Check dependencies
check_dependencies() {
    echo -e "${YELLOW}🔍 Checking dependencies...${NC}"

    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not installed${NC}"
        echo "Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo -e "${RED}❌ jq is not installed${NC}"
        echo "Install: brew install jq (macOS) or apt install jq (Linux)"
        exit 1
    fi

    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS CLI is not configured correctly${NC}"
        echo "Run: aws configure"
        exit 1
    fi

    echo -e "${GREEN}✓ All dependencies are installed${NC}"
}

# Get all zones or specific zones
get_zones() {
    if [ "$1" == "--all" ]; then
        echo -e "${YELLOW}📋 Getting all Route53 zones...${NC}"
        aws route53 list-hosted-zones --query 'HostedZones[*].{Id:Id,Name:Name}' --output json
    else
        echo -e "${YELLOW}📋 Searching for specific zones...${NC}"
        # Search zones by name
        local zones="["
        for domain in "$@"; do
            zone_id=$(aws route53 list-hosted-zones-by-name \
                --dns-name "$domain" \
                --query "HostedZones[?Name=='${domain}.'].Id" \
                --output text | cut -d'/' -f3)

            if [ -n "$zone_id" ]; then
                if [ "$zones" != "[" ]; then
                    zones+=","
                fi
                zones+="{\"Id\":\"/hostedzone/$zone_id\",\"Name\":\"${domain}.\"}"
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

    aws route53 list-resource-record-sets \
        --hosted-zone-id "$zone_id" \
        --query 'ResourceRecordSets[?Type!=`NS` && Type!=`SOA`]' \
        --output json
}

# Convert AWS records to module format
convert_records() {
    local records=$1

    echo "$records" | jq '[.[] | {
        name: (.Name | rtrimstr(".") | split(".")[0] // ""),
        type: .Type,
        value: (
            if .ResourceRecords then
                .ResourceRecords[0].Value
            elif .AliasTarget then
                .AliasTarget.DNSName
            else
                ""
            end
        ),
        ttl: (.TTL // 300),
        priority: (
            if .Type == "MX" then
                (.ResourceRecords[0].Value | split(" ")[0] | tonumber)
            else
                null
            end
        ),
        alias: (
            if .AliasTarget then
                {
                    name: .AliasTarget.DNSName,
                    zone_id: .AliasTarget.HostedZoneId,
                    evaluate_target_health: .AliasTarget.EvaluateTargetHealth
                }
            else
                null
            end
        )
    } | del(.alias | select(. == null)) | del(.priority | select(. == null))]'
}

# Main
main() {
    echo -e "${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       AWS ROUTE53 DNS EXPORT                                   ║"
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
        zone_id=$(echo "$zone" | jq -r '.Id' | cut -d'/' -f3)
        zone_name=$(echo "$zone" | jq -r '.Name' | sed 's/\.$//')
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

        config+="\"$zone_key\":{\"domain\":\"$zone_name\",\"comment\":\"Exported from AWS Route53\",\"records\":$converted_records}"
    done

    config+="}"

    # Save file
    output_file="aws-dns-export.json"
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
