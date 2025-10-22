# Multi-Provider DNS Terraform Module

A robust and flexible Terraform module for managing DNS zones and records across multiple providers with a unified interface. Simplifies provider migration without rewriting your entire configuration.

## Features

- **Multi-Provider Support**: AWS Route53, Cloudflare, and Vercel
- **Dual Input**: Accepts both JSON files and Terraform variables
- **Built-in Validation**: Verifies record compatibility with each provider
- **Easy Migration**: Included scripts for exporting/importing between providers
- **Provider-Specific Features**: Supports unique capabilities of each provider
  - AWS: Alias records, delegation sets
  - Cloudflare: Proxy mode (CDN + DDoS protection)
  - Vercel: Native integration with Vercel projects
- **Well Documented**: Complete examples and step-by-step guides

## Supported Providers

| Provider | Minimum Version | Special Features |
|----------|----------------|------------------|
| AWS Route53 | 5.0.0 | Alias records, delegation sets, health checks |
| Cloudflare | 4.0.0 | Proxy mode, DDoS protection, CDN |
| Vercel | 1.0.0 | Integration with Vercel projects |

## Quick Start

### 1. Installation

```hcl
module "dns" {
  source = "github.com/your-org/dns-terraform-module"

  provider_type    = "cloudflare"
  dns_config_file  = "${path.module}/dns-config.json"

  # Cloudflare-specific configuration
  cloudflare_account_id = var.cloudflare_account_id

  enable_validation = true
}
```

### 2. Configure JSON File

Create `dns-config.json`:

```json
{
  "primary": {
    "domain": "example.com",
    "records": [
      {
        "name": "",
        "type": "A",
        "value": "192.0.2.1",
        "ttl": 300
      },
      {
        "name": "www",
        "type": "CNAME",
        "value": "example.com",
        "ttl": 300
      }
    ]
  }
}
```

### 3. Apply

```bash
terraform init
terraform plan
terraform apply
```

## Usage

### Option 1: JSON File (Recommended)

```hcl
module "dns" {
  source = "./dns_terraform_module"

  provider_type   = "aws"
  dns_config_file = "${path.module}/dns-config.json"

  aws_region = "us-east-1"
}
```

### Option 2: Terraform Variables

```hcl
module "dns" {
  source = "./dns_terraform_module"

  provider_type = "cloudflare"

  dns_zones = {
    primary = {
      domain = "example.com"
      records = [
        {
          name    = "www"
          type    = "A"
          value   = "192.0.2.1"
          ttl     = 300
          proxied = true  # Cloudflare proxy
        }
      ]
    }
  }

  cloudflare_account_id = var.cloudflare_account_id
}
```

## Project Structure

```
dns_terraform_module/
├── README.md                    # This file
├── main.tf                      # Main orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Module outputs
├── versions.tf                  # Provider versions
├── providers.tf                 # Provider configuration examples
├── locals.tf                    # Transformations and validation
├── modules/                     # Provider-specific submodules
│   ├── aws-route53/
│   ├── cloudflare/
│   └── vercel/
├── examples/                    # Usage examples
│   ├── aws-route53/
│   ├── cloudflare/
│   └── vercel/
├── scripts/                     # Migration tools
│   ├── export-aws.sh
│   ├── export-cloudflare.sh
│   ├── export-vercel.sh
│   ├── validate-config.py
│   └── migrate.sh
└── schemas/
    └── dns-config.schema.json   # JSON Schema
```

## Provider Comparison

| Feature | AWS Route53 | Cloudflare | Vercel |
|---------|-------------|------------|--------|
| **Record Types** | A, AAAA, CNAME, MX, TXT, NS, SOA, SRV, PTR, CAA, NAPTR, SPF | A, AAAA, CNAME, MX, TXT, NS, SRV, CAA, HTTPS, SVCB, TLSA, URI, LOC | A, AAAA, CNAME, MX, TXT, CAA, SRV, ALIAS |
| **CDN/Proxy** | ❌ | ✅ (Proxy mode) | ❌ |
| **DDoS Protection** | ❌ | ✅ | ❌ |
| **Alias Records** | ✅ | ❌ | ✅ (ALIAS type) |
| **Minimum TTL** | 60s | 60s (1s with proxy) | 60s |
| **Health Checks** | ✅ | ✅ | ❌ |
| **Pricing** | $0.50/zone + queries | Generous free tier | Included with project |
| **Best For** | AWS infrastructure | Public sites, CDN | Apps on Vercel |

## DNS Record Types

### Basic Records

```json
{
  "records": [
    {
      "name": "",
      "type": "A",
      "value": "192.0.2.1",
      "ttl": 300
    },
    {
      "name": "www",
      "type": "CNAME",
      "value": "example.com",
      "ttl": 300
    },
    {
      "name": "",
      "type": "MX",
      "value": "mail.example.com",
      "ttl": 300,
      "priority": 10
    },
    {
      "name": "",
      "type": "TXT",
      "value": "v=spf1 include:_spf.example.com ~all",
      "ttl": 300
    }
  ]
}
```

### AWS Route53: Alias Records

```json
{
  "name": "cdn",
  "type": "A",
  "value": "",
  "ttl": 300,
  "alias": {
    "name": "d111111abcdef8.cloudfront.net",
    "zone_id": "Z2FDTNDATAQYW2",
    "evaluate_target_health": false
  }
}
```

### Cloudflare: Proxy Mode

```json
{
  "name": "www",
  "type": "A",
  "value": "192.0.2.1",
  "ttl": 1,
  "proxied": true
}
```

## Provider Migration

### Method 1: Automated Script

```bash
# Migrate from AWS to Cloudflare
./scripts/migrate.sh --from aws --to cloudflare --domain example.com

# Migrate all zones
./scripts/migrate.sh --from cloudflare --to vercel --all
```

### Method 2: Manual

1. **Export from source provider**:

```bash
# AWS
export AWS_PROFILE=my-profile
./scripts/export-aws.sh example.com

# Cloudflare
export CF_API_TOKEN="your-token"
./scripts/export-cloudflare.sh example.com

# Vercel
export VERCEL_TOKEN="your-token"
./scripts/export-vercel.sh example.com
```

2. **Validate configuration**:

```bash
./scripts/validate-config.py aws-dns-export.json --provider cloudflare
```

3. **Apply to new provider**:

```hcl
module "dns" {
  source = "./dns_terraform_module"

  provider_type   = "cloudflare"
  dns_config_file = "aws-dns-export.json"

  cloudflare_account_id = var.cloudflare_account_id
}
```

4. **Update nameservers** at your domain registrar

5. **Verify propagation**:

```bash
dig NS example.com
dig example.com
```

## Input Variables

### General

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `provider_type` | string | ✅ | - | Provider: `aws`, `cloudflare`, or `vercel` |
| `dns_config_file` | string | ❌ | null | Path to JSON configuration file |
| `dns_zones` | map(object) | ❌ | {} | Configuration via variables |
| `enable_validation` | bool | ❌ | true | Validate compatibility |
| `default_ttl` | number | ❌ | 300 | Default TTL (60-86400) |
| `tags` | map(string) | ❌ | {} | Default tags |

### AWS Route53

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `aws_region` | string | ❌ | us-east-1 | AWS region |
| `aws_delegation_set_id` | string | ❌ | null | Delegation set ID |
| `aws_force_destroy` | bool | ❌ | false | Allow destroy with records |

### Cloudflare

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `cloudflare_account_id` | string | ✅* | null | Account ID (required with Cloudflare) |
| `cloudflare_zone_plan` | string | ❌ | free | Plan: free, pro, business, enterprise |
| `cloudflare_zone_type` | string | ❌ | full | Type: full, partial |

### Vercel

| Variable | Type | Required | Default | Description |
|----------|------|----------|---------|-------------|
| `vercel_team_id` | string | ❌ | null | Team ID (for team accounts) |

## Outputs

| Output | Description |
|--------|-------------|
| `provider` | Provider used |
| `zone_ids` | IDs of created zones |
| `name_servers` | Nameservers to configure at registrar |
| `zones` | Complete zone information |
| `module_info` | Metadata and statistics |
| `next_steps` | Post-deployment instructions |

## Examples

See the `examples/` directory for complete examples:

- [AWS Route53](./examples/aws-route53/)
- [Cloudflare](./examples/cloudflare/)
- [Vercel](./examples/vercel/)

## Best Practices

### 1. Use Remote State

```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "dns/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### 2. Separate Environments

```
terraform/
├── production/
│   └── dns/
├── staging/
│   └── dns/
└── development/
    └── dns/
```

### 3. Version Your Configuration

```bash
git tag -a dns-v1.0.0 -m "Initial DNS configuration"
git push --tags
```

### 4. Regular Backups

```bash
# Export current configuration
./scripts/export-cloudflare.sh --all
git add cloudflare-dns-export.json
git commit -m "Backup DNS $(date +%Y-%m-%d)"
```

### 5. Test in Staging

Always test DNS changes on staging domains first.

## Troubleshooting

### Error: "Invalid cloudflare_account_id"

Verify that `cloudflare_account_id` is configured. You can find it in the Cloudflare Dashboard.

### Error: "Unsupported record type"

Check the compatibility table. Some record types are not supported by all providers.

### Slow DNS Propagation

- DNS can take up to 48 hours to propagate globally
- Use tools like https://dnschecker.org to verify
- Lower TTL before making important changes

### Corrupted Terraform State

```bash
terraform state list
terraform state pull > backup.tfstate
# If necessary:
terraform import module.dns.module.aws_route53[0].aws_route53_zone.this[\"primary\"] ZONE_ID
```

## Security

### Credential Management

❌ **DON'T DO THIS**:
```hcl
cloudflare_api_token = "your-token-here"  # Never in code!
```

✅ **DO THIS**:
```bash
export TF_VAR_cloudflare_api_token="your-token"
terraform apply
```

Or use Terraform Cloud / AWS Secrets Manager / Vault.

### Minimum Permissions

- **AWS**: Route53 only (`route53:*`)
- **Cloudflare**: Zone DNS Edit + Zone Read
- **Vercel**: DNS write access

## FAQ

**Q: Can I use multiple providers simultaneously?**
A: Not in the same module invocation. Each module instance manages zones in a single provider. Use multiple module instances to manage different providers.

**Q: How do I migrate without downtime?**
A: 1) Create records in new provider, 2) Lower TTL to minimum, 3) Wait for TTL, 4) Change nameservers, 5) Verify, 6) Clean up old provider.

**Q: Does it support DNSSEC?**
A: DNSSEC must be configured manually in each provider after deployment.

**Q: What if I delete the state file?**
A: Use `terraform import` to re-import resources. Export scripts help rebuild configuration.

## Contributing

Contributions are welcome:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create a Pull Request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/your-org/dns-terraform-module/issues)
- 📖 **Documentation**: [Wiki](https://github.com/your-org/dns-terraform-module/wiki)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/your-org/dns-terraform-module/discussions)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.

## Resources

- [Terraform AWS Provider - Route53](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform Vercel Provider](https://registry.terraform.io/providers/vercel/vercel/latest/docs)
- [DNS Best Practices](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/best-practices-dns.html)
- [Cloudflare DNS Documentation](https://developers.cloudflare.com/dns/)

---

Made with ❤️ to simplify DNS management with Terraform
