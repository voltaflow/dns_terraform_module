# Vercel Submodule

This submodule manages DNS records in Vercel.

## Features

- Manages DNS records for Vercel domains
- Automatic domain handling (no separate zone resource)
- Support for MX and SRV record priorities
- Team account support
- Integration with Vercel projects

## Usage

This module is designed to be called by the parent DNS module and should not typically be used directly. However, if you need to use it standalone:

```hcl
module "vercel" {
  source = "./modules/vercel"

  zones = {
    example = {
      domain = "example.com"
      records = [
        {
          name     = "www"
          type     = "CNAME"
          value    = "cname.vercel-dns.com"
          ttl      = 60
          priority = null
        }
      ]
      zone_config = {
        team_id = null  # Optional
      }
    }
  }
}
```

## Input Variables

### zones

**Type**: `map(object)`
**Required**: Yes

Complex object containing zone configurations. Each zone must have:

- `domain` (string): The domain name
- `records` (list): List of DNS records
- `zone_config` (object): Zone-specific configuration
  - `team_id` (string, optional): Vercel team ID for team accounts

Each record in `records` must have:

- `name` (string): Record name (subdomain or empty for apex)
- `type` (string): DNS record type
- `value` (string): Record value
- `ttl` (number): Time to live (minimum 60 seconds)
- `priority` (number, optional): For MX/SRV records

## Outputs

### domains

List of unique domains managed.

**Type**: `list(string)`

### zones

Zone information (Vercel doesn't have separate zone IDs).

**Type**: `map(object)`

Contains:
- `domain`: The domain name

**Note**: Vercel nameservers are not available via Terraform and must be checked in the Vercel Dashboard.

### records

Information about all created records.

**Type**: `map(object)`

Contains:
- `id`: Record ID
- `domain`: Domain name
- `name`: Record name
- `type`: Record type
- `value`: Record value

### record_ids

IDs of all DNS records.

**Type**: `map(string)`

## Vercel DNS Architecture

### No Separate "Zone" Resource

Unlike AWS Route53 and Cloudflare, Vercel doesn't have a separate zone resource. Domains are automatically created when you add the first DNS record.

### Nameservers

Vercel nameservers cannot be retrieved via Terraform. You must:

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Navigate to your domain
3. Copy the provided nameservers
4. Configure them at your domain registrar

## Record Types

### Supported Types

- **A**: IPv4 address
- **AAAA**: IPv6 address
- **ALIAS**: Alias record (similar to CNAME for apex)
- **CAA**: Certificate Authority Authorization
- **CNAME**: Canonical name
- **MX**: Mail exchange
- **SRV**: Service locator
- **TXT**: Text

### Vercel-Specific Values

#### A Records (Apex Domain)

```hcl
{
  name  = ""
  type  = "A"
  value = "76.76.21.21"  # Vercel's IP
  ttl   = 60
}
```

#### CNAME Records (Subdomains)

```hcl
{
  name  = "www"
  type  = "CNAME"
  value = "cname.vercel-dns.com"  # Vercel's CNAME
  ttl   = 60
}
```

## MX Records

MX records require special handling with `mx_priority`:

```hcl
{
  name     = ""
  type     = "MX"
  value    = "mail.example.com"
  ttl      = 300
  priority = 10
}
```

## SRV Records

SRV records require special configuration. Note that Vercel may require additional fields (weight, port) that should be included in the value or parsed separately.

```hcl
{
  name     = "_service._tcp"
  type     = "SRV"
  value    = "target.example.com"
  ttl      = 300
  priority = 10
}
```

## Domain Verification

Vercel requires domain verification:

### 1. Add Verification Record

```hcl
{
  name  = "_vercel"
  type  = "TXT"
  value = "vc-domain-verify=example.com,your-verification-code"
  ttl   = 60
}
```

### 2. Wait for Verification

Vercel automatically detects the TXT record. This may take a few minutes.

### 3. Check Status

Verify in [Vercel Dashboard](https://vercel.com/dashboard) that the domain shows as "Verified".

## Connecting to Projects

### Via Dashboard

1. Go to your project in Vercel
2. Navigate to Settings → Domains
3. Add your domain
4. Vercel will automatically configure

### Via Terraform (Additional Resource)

```hcl
resource "vercel_project_domain" "example" {
  project_id = vercel_project.my_project.id
  domain     = "example.com"
}
```

## TTL Limitations

- **Minimum TTL**: 60 seconds
- **Recommended TTL**: 60 seconds for flexibility
- Higher TTLs reduce DNS query load but slow propagation

## Team Accounts

For team accounts, provide the team ID:

```hcl
zone_config = {
  team_id = "team_xxxxxxxxxx"
}
```

Find your team ID:
1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. Select your team
3. The team ID is in the URL: `vercel.com/{team_id}/...`

## Resource Naming

Resources are created with the following naming pattern:

- Records: `vercel_dns_record.this["zone_key--name--type--index"]`

## Permissions Required

The Vercel API token must have:

- DNS write access
- Domain management permissions

## Notes

- Domains are created automatically when adding records
- Nameservers must be configured manually at the registrar
- Domain verification is required before full functionality
- Vercel provides automatic SSL certificates
- DNS propagation typically takes 5-15 minutes
- Some record types may have limited functionality compared to full DNS providers

## Common Use Cases

### Static Website

```hcl
# Apex domain
{
  name  = ""
  type  = "A"
  value = "76.76.21.21"
  ttl   = 60
}

# www subdomain
{
  name  = "www"
  type  = "CNAME"
  value = "cname.vercel-dns.com"
  ttl   = 60
}
```

### With Email (External Provider)

```hcl
# MX records for email
{
  name     = ""
  type     = "MX"
  value    = "mx1.emailprovider.com"
  priority = 10
  ttl      = 300
}

# SPF record
{
  name  = ""
  type  = "TXT"
  value = "v=spf1 include:_spf.emailprovider.com ~all"
  ttl   = 300
}
```

## Resources

- [Vercel DNS Documentation](https://vercel.com/docs/concepts/projects/custom-domains)
- [Terraform Vercel Provider](https://registry.terraform.io/providers/vercel/vercel/latest/docs)
- [Vercel API Documentation](https://vercel.com/docs/rest-api)
