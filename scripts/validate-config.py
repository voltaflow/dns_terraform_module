#!/usr/bin/env python3

"""
DNS Configuration Validator

This script validates DNS configuration JSON files against the schema
and checks compatibility with supported providers.

Usage:
    ./validate-config.py <file.json>
    ./validate-config.py <file.json> --provider aws
    ./validate-config.py <file.json> --provider cloudflare --strict

Requirements:
    pip install jsonschema
"""

import json
import sys
import argparse
from pathlib import Path
from typing import Dict, List, Tuple

try:
    from jsonschema import validate, ValidationError, Draft7Validator
except ImportError:
    print("❌ Error: jsonschema is not installed")
    print("Install with: pip install jsonschema")
    sys.exit(1)


# Record types supported by each provider
SUPPORTED_RECORD_TYPES = {
    'aws': [
        'A', 'AAAA', 'CAA', 'CNAME', 'MX', 'NAPTR', 'NS',
        'PTR', 'SOA', 'SPF', 'SRV', 'TXT'
    ],
    'cloudflare': [
        'A', 'AAAA', 'CAA', 'CNAME', 'HTTPS', 'TXT', 'SRV',
        'LOC', 'MX', 'NS', 'CERT', 'DNSKEY', 'DS', 'NAPTR',
        'SMIMEA', 'SSHFP', 'SVCB', 'TLSA', 'URI'
    ],
    'vercel': [
        'A', 'AAAA', 'ALIAS', 'CAA', 'CNAME', 'MX', 'SRV', 'TXT'
    ]
}


class Colors:
    """ANSI color codes for terminal output"""
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    NC = '\033[0m'  # No Color


def load_schema() -> Dict:
    """Load the JSON Schema"""
    schema_path = Path(__file__).parent.parent / 'schemas' / 'dns-config.schema.json'

    if not schema_path.exists():
        print(f"{Colors.RED}❌ Error: Schema not found at {schema_path}{Colors.NC}")
        sys.exit(1)

    with open(schema_path, 'r') as f:
        return json.load(f)


def load_config(config_file: str) -> Dict:
    """Load the JSON configuration file"""
    try:
        with open(config_file, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"{Colors.RED}❌ Error: File not found: {config_file}{Colors.NC}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"{Colors.RED}❌ Error: Invalid JSON{Colors.NC}")
        print(f"   {e}")
        sys.exit(1)


def validate_schema(config: Dict, schema: Dict) -> Tuple[bool, List[str]]:
    """Validate configuration against the schema"""
    errors = []

    try:
        validator = Draft7Validator(schema)
        for error in validator.iter_errors(config):
            errors.append(f"  • {error.message} (path: {'.'.join(str(p) for p in error.path)})")

        return len(errors) == 0, errors
    except Exception as e:
        errors.append(f"  • {str(e)}")
        return False, errors


def check_provider_compatibility(config: Dict, provider: str = None) -> Tuple[bool, List[str]]:
    """Check compatibility with providers"""
    warnings = []

    for zone_key, zone_config in config.items():
        for idx, record in enumerate(zone_config.get('records', [])):
            record_type = record.get('type', '').upper()

            # Check compatibility with specific provider
            if provider:
                if record_type not in SUPPORTED_RECORD_TYPES[provider]:
                    warnings.append(
                        f"  ⚠️  {zone_key}/{record.get('name', '@')} - "
                        f"Type '{record_type}' not supported by {provider}"
                    )

            # Check proxied (Cloudflare only)
            if record.get('proxied', False):
                if provider and provider != 'cloudflare':
                    warnings.append(
                        f"  ⚠️  {zone_key}/{record.get('name', '@')} - "
                        f"'proxied' is only supported by Cloudflare"
                    )
                if record_type not in ['A', 'AAAA', 'CNAME']:
                    warnings.append(
                        f"  ⚠️  {zone_key}/{record.get('name', '@')} - "
                        f"'proxied' only works with A, AAAA, CNAME"
                    )

            # Check alias (AWS only)
            if record.get('alias'):
                if provider and provider != 'aws':
                    warnings.append(
                        f"  ⚠️  {zone_key}/{record.get('name', '@')} - "
                        f"'alias' is only supported by AWS Route53"
                    )

            # Check MX priority
            if record_type == 'MX' and not record.get('priority'):
                warnings.append(
                    f"  ⚠️  {zone_key}/{record.get('name', '@')} - "
                    f"MX records require 'priority'"
                )

    return len(warnings) == 0, warnings


def get_statistics(config: Dict) -> Dict:
    """Get configuration statistics"""
    stats = {
        'zones': len(config),
        'total_records': 0,
        'record_types': {},
        'zones_list': []
    }

    for zone_key, zone_config in config.items():
        records = zone_config.get('records', [])
        stats['total_records'] += len(records)
        stats['zones_list'].append({
            'key': zone_key,
            'domain': zone_config.get('domain'),
            'records_count': len(records)
        })

        # Count record types
        for record in records:
            record_type = record.get('type', 'UNKNOWN')
            stats['record_types'][record_type] = stats['record_types'].get(record_type, 0) + 1

    return stats


def print_header():
    """Print header"""
    print(f"{Colors.GREEN}")
    print("╔════════════════════════════════════════════════════════════════╗")
    print("║       DNS CONFIGURATION VALIDATOR                              ║")
    print("╚════════════════════════════════════════════════════════════════╝")
    print(f"{Colors.NC}\n")


def print_statistics(stats: Dict):
    """Print statistics"""
    print(f"{Colors.BLUE}📊 Statistics:{Colors.NC}")
    print(f"  • Zones: {stats['zones']}")
    print(f"  • Total records: {stats['total_records']}")
    print(f"\n  Configured zones:")
    for zone in stats['zones_list']:
        print(f"    - {zone['domain']} ({zone['records_count']} records)")

    print(f"\n  Record types:")
    for record_type, count in sorted(stats['record_types'].items()):
        print(f"    - {record_type}: {count}")
    print()


def main():
    parser = argparse.ArgumentParser(
        description='Validate DNS configuration for the Terraform module'
    )
    parser.add_argument('config_file', help='JSON configuration file')
    parser.add_argument(
        '--provider',
        choices=['aws', 'cloudflare', 'vercel'],
        help='Validate compatibility with a specific provider'
    )
    parser.add_argument(
        '--strict',
        action='store_true',
        help='Strict mode: fail if there are warnings'
    )

    args = parser.parse_args()

    print_header()

    # Load schema and configuration
    print(f"{Colors.YELLOW}🔍 Loading files...{Colors.NC}")
    schema = load_schema()
    config = load_config(args.config_file)
    print(f"{Colors.GREEN}✓ Files loaded successfully{Colors.NC}\n")

    # Validate schema
    print(f"{Colors.YELLOW}🔍 Validating JSON structure...{Colors.NC}")
    schema_valid, schema_errors = validate_schema(config, schema)

    if schema_valid:
        print(f"{Colors.GREEN}✓ Valid JSON structure{Colors.NC}\n")
    else:
        print(f"{Colors.RED}❌ Schema validation errors:{Colors.NC}")
        for error in schema_errors:
            print(error)
        print()
        sys.exit(1)

    # Statistics
    stats = get_statistics(config)
    print_statistics(stats)

    # Check provider compatibility
    if args.provider:
        print(f"{Colors.YELLOW}🔍 Checking compatibility with {args.provider}...{Colors.NC}")
        compat_ok, compat_warnings = check_provider_compatibility(config, args.provider)

        if compat_ok:
            print(f"{Colors.GREEN}✓ Compatible with {args.provider}{Colors.NC}\n")
        else:
            print(f"{Colors.YELLOW}⚠️  Compatibility warnings with {args.provider}:{Colors.NC}")
            for warning in compat_warnings:
                print(warning)
            print()

            if args.strict:
                print(f"{Colors.RED}❌ Validation failed in strict mode{Colors.NC}")
                sys.exit(1)
    else:
        # Check general compatibility
        print(f"{Colors.YELLOW}🔍 Checking general compatibility...{Colors.NC}")
        all_compat = True
        for provider in ['aws', 'cloudflare', 'vercel']:
            compat_ok, _ = check_provider_compatibility(config, provider)
            status = f"{Colors.GREEN}✓{Colors.NC}" if compat_ok else f"{Colors.YELLOW}⚠{Colors.NC}"
            print(f"  {status} {provider}")
        print()

    # Final result
    print(f"{Colors.GREEN}╔════════════════════════════════════════════════════════════════╗{Colors.NC}")
    print(f"{Colors.GREEN}║  ✅ VALIDATION COMPLETED SUCCESSFULLY                          ║{Colors.NC}")
    print(f"{Colors.GREEN}╚════════════════════════════════════════════════════════════════╝{Colors.NC}")
    print()
    print(f"✅ Configuration is valid and ready to use")
    print()


if __name__ == '__main__':
    main()
