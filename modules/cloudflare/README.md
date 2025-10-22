# Cloudflare Submodule

This submodule manages DNS zones and records in Cloudflare.

## Features

- Creates Cloudflare DNS zones
- Manages DNS records with full Cloudflare feature support
- Cloudflare proxy mode (orange cloud) for CDN and DDoS protection
- Automatic TTL adjustment for proxied records
- Support for all Cloudflare record types
- Zone plan and type configuration

## Usage

This module is designed to be called by the parent DNS module and should not typically be used directly. However, if you need to use it standalone:

```hcl
module "cloudflare" {
  source = "./modules/cloudflare"

  zones = {
    example = {
      domain = "example.com"
      records = [
        {
          name     = "www"
          type     = "A"
          value    = "192.0.2.1"
          ttl      = 1
          priority = null
          proxied  = true
        }
      ]
      zone_config = {
        account_id = "your-account-id"
        plan       = "free"
        type       = "full"
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
  - `account_id` (string): Cloudflare account ID (required)
  - `plan` (string): Zone plan (free, pro, business, enterprise)
  - `type` (string): Zone type (full, partial)

Each record in `records` must have:

- `name` (string): Record name (subdomain or empty for apex)
- `type` (string): DNS record type
- `value` (string): Record value
- `ttl` (number): Time to live (1 for automatic when proxied)
- `priority` (number, optional): For MX/SRV records
- `proxied` (bool): Enable Cloudflare proxy (only for A, AAAA, CNAME)

## Outputs

### zone_ids

IDs of the created Cloudflare zones.

**Type**: `map(string)`

### name_servers

Name servers assigned to each zone.

**Type**: `map(list(string))`

### zones

Complete information about each created zone.

**Type**: `map(object)`

Contains:
- `zone_id`: The zone ID
- `name_servers`: List of nameservers
- `domain`: The domain name
- `status`: Zone status (active, pending, etc.)
- `verification_key`: Domain verification key

### record_hostnames

Hostnames of all created records.

**Type**: `map(string)`

### proxied_records

Records that have Cloudflare proxy enabled.

**Type**: `map(bool)`

## Proxy Mode

Cloudflare's proxy mode (orange cloud) provides CDN caching and DDoS protection.

### Benefits

- **CDN**: Global content delivery network
- **DDoS Protection**: Automatic mitigation
- **SSL/TLS**: Free SSL certificates
- **Web Application Firewall**: Security rules
- **Performance**: Optimization and caching

### Supported Record Types

Proxy mode only works with:
- A (IPv4 addresses)
- AAAA (IPv6 addresses)
- CNAME (Canonical names)

### TTL Behaviour

When `proxied = true`, TTL is automatically set to 1 (automatic). The actual TTL is managed by Cloudflare.

### Example

```hcl
# Proxied (orange cloud) - CDN + DDoS protection
{
  name    = "www"
  type    = "A"
  value   = "192.0.2.1"
  ttl     = 1
  proxied = true
}

# DNS only (grey cloud) - Direct IP exposure
{
  name    = "direct"
  type    = "A"
  value   = "192.0.2.50"
  ttl     = 300
  proxied = false
}
```

## Zone Plans

### Free
- Unlimited bandwidth
- DDoS protection
- Shared SSL certificate
- 3 Page Rules

### Pro ($20/month)
- Everything in Free
- Dedicated SSL certificate
- 20 Page Rules
- Web Application Firewall
- Image optimization

### Business ($200/month)
- Everything in Pro
- 50 Page Rules
- Advanced DDoS protection
- Custom SSL
- Priority support

### Enterprise (Custom pricing)
- Everything in Business
- 125 Page Rules
- Dedicated support
- Custom contracts
- Advanced security features

## Record Types

### Supported Types

- **A**: IPv4 address
- **AAAA**: IPv6 address
- **CAA**: Certificate Authority Authorization
- **CNAME**: Canonical name
- **HTTPS**: HTTPS record
- **TXT**: Text
- **SRV**: Service locator
- **LOC**: Location
- **MX**: Mail exchange
- **NS**: Name server
- **CERT**: Certificate
- **DNSKEY**: DNS public key
- **DS**: Delegation Signer
- **NAPTR**: Name Authority Pointer
- **SMIMEA**: S/MIME Certificate Association
- **SSHFP**: SSH Fingerprint
- **SVCB**: Service Binding
- **TLSA**: TLS Authentication
- **URI**: Uniform Resource Identifier

## Zone Types

### Full (Recommended)

- Cloudflare manages all DNS records
- Full proxy capabilities
- Complete DDoS protection
- Requires changing nameservers at registrar

### Partial (CNAME Setup)

- Keep existing nameservers
- Limited to specific subdomains
- Proxy only for configured subdomains
- Requires CNAME records at current DNS provider

## Resource Naming

Resources are created with the following naming pattern:

- Zones: `cloudflare_zone.this["zone_key"]`
- Records: `cloudflare_record.this["zone_key--name--type--index"]`

## Permissions Required

The Cloudflare API token must have:

- **Zone - DNS - Edit**: To manage DNS records
- **Zone - Zone - Read**: To read zone information
- **Zone - Zone Settings - Edit**: To modify zone settings

## Import Existing Records

Cloudflare records are created with `allow_overwrite = true`, which allows importing existing records:

```bash
terraform import 'module.cloudflare.cloudflare_record.this["key"]' zone_id/record_id
```

## Notes

- Proxied records always have TTL of 1 (automatic)
- Zone status must be "active" before full functionality
- Nameserver propagation can take up to 24 hours
- Free plan includes unlimited DNS queries
- Cloudflare provides IPv6 support automatically

## Resources

- [Cloudflare DNS Documentation](https://developers.cloudflare.com/dns/)
- [Terraform Cloudflare Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Cloudflare API Documentation](https://developers.cloudflare.com/api/)
