# Example: Vercel

This example shows how to use the DNS module with Vercel.

## Prerequisites

1. Vercel Account
2. Vercel API Token
3. Terraform >= 1.3.0

## Getting API Token

1. Go to: https://vercel.com/account/tokens
2. Click on "Create Token"
3. Give it a descriptive name (e.g. "Terraform DNS")
4. Select the required scope
5. Save the token securely

## Configuration

### Method 1: Environment Variables

```bash
export TF_VAR_vercel_api_token="your-api-token"
# Optional for teams:
export TF_VAR_vercel_team_id="team_xxxxxxxxxx"
terraform apply
```

### Method 2: terraform.tfvars File

Create a `terraform.tfvars` file:

```hcl
vercel_api_token = "your-api-token"
# vercel_team_id = "team_xxxxxxxxxx"  # Optional
```

**IMPORTANT**: Add `terraform.tfvars` to `.gitignore`.

## Running the Example

```bash
terraform init
terraform plan
terraform apply
```

## Vercel DNS Features

### Domains and Projects

Vercel handles domains differently from AWS/Cloudflare:

- Domains are added automatically when you create records
- A domain can point to a Vercel project
- Vercel provides specific IPs and CNAMEs

### Vercel IPs

Vercel has specific IPs for A records:

```
76.76.21.21
```

### Vercel CNAME

For subdomains, use the Vercel CNAME:

```
cname.vercel-dns.com
```

### Supported Record Types

Vercel supports the following types:

- **A**: IPv4 addresses
- **AAAA**: IPv6 addresses
- **ALIAS**: Alias records (similar to CNAME for apex)
- **CAA**: Certificate Authority Authorization
- **CNAME**: Canonical name records
- **MX**: Mail exchange records
- **SRV**: Service records
- **TXT**: Text records

## Vercel Limitations

1. **No "zone" concept**: Domains are created automatically
2. **Nameservers**: Must be checked from Vercel Dashboard, not available via Terraform
3. **Verification**: You must verify the domain in Vercel Dashboard after creating records
4. **TTL**: Minimum TTL is 60 seconds

## Connecting to a Vercel Project

To connect your domain to a Vercel project:

1. **Via Dashboard**:
   - Go to your project in Vercel
   - Settings → Domains
   - Add your domain

2. **Via Terraform** (additional resource):

```hcl
resource "vercel_project_domain" "example" {
  project_id = vercel_project.my_project.id
  domain     = "example.com"
}
```

## Domain Verification

Vercel requires verifying that you own the domain:

1. Create a TXT record with the verification code
2. Wait for Vercel to detect it (may take a few minutes)
3. The domain will be marked as "verified"

```json
{
  "name": "_vercel",
  "type": "TXT",
  "value": "vc-domain-verify=example.com,your-verification-code",
  "ttl": 60
}
```

## Outputs

After `terraform apply`:

- **domains**: List of managed domains
- **records**: IDs of created DNS records

## Next Steps

1. **Check Nameservers**: Go to https://vercel.com/dashboard and find your domain
2. **Configure at Registrar**: Set up Vercel nameservers at your registrar
3. **Verify Domain**: Verify the domain in Vercel Dashboard
4. **Connect to Project**: Connect the domain to a Vercel project

## DNS Verification

```bash
# View A records
dig example.com

# View CNAME records
dig www.example.com

# View MX records
dig MX example.com
```

## Clean Up

```bash
terraform destroy
```

## Troubleshooting

### Error: "Invalid API Token"

Verify that the token is correct and has the necessary permissions.

### Error: "Team not found"

If using a team account, make sure to pass the correct `vercel_team_id`.

### Domain not verifying

Make sure that:
1. Nameservers are correctly configured
2. The TXT verification record exists
3. You have waited long enough for DNS propagation

### Nameservers not appearing in outputs

This is normal. Vercel does not expose nameservers via Terraform. You must check them from:
https://vercel.com/dashboard → Your domain → Nameservers

## Additional Resources

- [Vercel DNS Documentation](https://vercel.com/docs/concepts/projects/custom-domains)
- [Vercel Terraform Provider](https://registry.terraform.io/providers/vercel/vercel/latest/docs)
- [Vercel API Reference](https://vercel.com/docs/rest-api)
