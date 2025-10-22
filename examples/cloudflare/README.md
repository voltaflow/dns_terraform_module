# Example: Cloudflare

This example demonstrates how to use the DNS module with Cloudflare.

## Prerequisites

1. Cloudflare account
2. API Token with permissions for Zone and DNS
3. Cloudflare Account ID
4. Terraform >= 1.3.0

## Obtaining Credentials

### 1. API Token (Recommended)

1. Go to: https://dash.cloudflare.com/profile/api-tokens
2. Click on "Create Token"
3. Use the "Edit zone DNS" template or create a custom one with:
   - **Zone - DNS - Edit**
   - **Zone - Zone - Read**
   - **Zone - Zone Settings - Edit**
4. Save the token securely

### 2. Account ID

1. Go to: https://dash.cloudflare.com
2. Select your domain
3. On the right side, under "API" you will find your **Account ID**

## Configuration

### Method 1: Environment Variables

```bash
export TF_VAR_cloudflare_api_token="your-api-token"
export TF_VAR_cloudflare_account_id="your-account-id"
terraform apply
```

### Method 2: terraform.tfvars File

Create a `terraform.tfvars` file:

```hcl
cloudflare_api_token  = "your-api-token"
cloudflare_account_id = "your-account-id"
cloudflare_zone_plan  = "free"  # or "pro", "business", "enterprise"
```

**IMPORTANT**: Add `terraform.tfvars` to `.gitignore` to avoid exposing credentials.

### Method 3: Terraform Cloud / Workspaces

Configure the variables as "sensitive" in Terraform Cloud.

## Running the Example

```bash
# Initialise
terraform init

# View plan
terraform plan

# Apply changes
terraform apply
```

## Cloudflare Features

### Proxy Mode

Cloudflare can act as a proxy (CDN + DDoS protection) for A, AAAA and CNAME records:

```json
{
  "name": "www",
  "type": "A",
  "value": "192.0.2.1",
  "ttl": 1,
  "proxied": true  // Cloudflare proxy enabled (orange cloud)
}
```

**Note**: When `proxied = true`, the TTL is automatically set to 1 (automatic).

### DNS Only Mode

To expose the real IP without Cloudflare protection:

```json
{
  "name": "direct",
  "type": "A",
  "value": "192.0.2.50",
  "ttl": 300,
  "proxied": false  // DNS only (grey cloud)
}
```

## Supported Record Types

Cloudflare supports many record types:

- **Basic**: A, AAAA, CNAME, MX, TXT
- **Email**: SPF, DKIM, DMARC (via TXT)
- **Security**: CAA, TLSA, SSHFP
- **Advanced**: SRV, NAPTR, LOC, URI
- **Modern**: HTTPS, SVCB

## Cloudflare Plans

- **free**: Free plan (default)
- **pro**: Pro plan ($20/month per domain)
- **business**: Business plan ($200/month per domain)
- **enterprise**: Enterprise plan (contact sales)

## Outputs

After `terraform apply`:

- **name_servers**: Cloudflare nameservers (e.g., `bob.ns.cloudflare.com`)
- **zone_ids**: Zone IDs
- **proxied_records**: List of records with proxy enabled

## Next Steps

1. **Configure Nameservers**: Go to your registrar and configure the Cloudflare nameservers
2. **Verify Status**: In Cloudflare Dashboard, verify that the status is "Active"
3. **Configure SSL/TLS**: Go to SSL/TLS settings and configure:
   - SSL/TLS encryption mode
   - Edge Certificates
4. **Configure Rules**: Page Rules, Firewall Rules, etc.

## Verification

```bash
# Verify nameservers
dig NS example.com

# Verify they point to Cloudflare
dig example.com

# View specific records
dig www.example.com
dig MX example.com
```

## Cleanup

```bash
terraform destroy
```

## Troubleshooting

### Error: "Invalid account_id"

Verify that the `cloudflare_account_id` is correct. You can find it in Cloudflare Dashboard.

### Error: "Invalid API Token"

The token must have sufficient permissions. Create a new one with the correct permissions.

### Zone does not activate

It may take up to 24 hours. Verify that the nameservers are correctly configured in your registrar.
