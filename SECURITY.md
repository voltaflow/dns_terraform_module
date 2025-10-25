# Security Policy

## Supported Versions

We release patches for security vulnerabilities. Currently supported versions:

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of our DNS Terraform module seriously. If you believe you have found a security vulnerability, please report it to us as described below.

### Where to Report

**Please do NOT report security vulnerabilities through public GitHub issues.**

Instead, please report them via:

1. **Email**: Send details to the repository maintainer
2. **GitHub Security Advisory**: Use the "Security" tab → "Report a vulnerability" feature

### What to Include

Please include the following information in your report:

- Type of vulnerability (e.g., credential exposure, injection, etc.)
- Full paths of source file(s) related to the manifestation of the vulnerability
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the vulnerability, including how an attacker might exploit it

### What to Expect

- **Initial Response**: Within 48 hours
- **Progress Updates**: Every 7 days until resolution
- **Resolution Timeline**: We aim to resolve critical issues within 30 days
- **Public Disclosure**: Coordinated with reporter after fix is deployed

### Safe Harbor

We support safe harbor for security researchers who:

- Make a good faith effort to avoid privacy violations, destruction of data, and interruption or degradation of our services
- Only interact with accounts you own or with explicit permission of the account holder
- Do not exploit a security issue beyond what is necessary to demonstrate it
- Report the vulnerability promptly after discovery

## Security Best Practices

When using this module, follow these security guidelines:

### 1. Credential Management

**❌ NEVER do this:**
```hcl
# DON'T hardcode credentials
cloudflare_api_token = "your-token-here"
vercel_api_token     = "your-token-here"
```

**✅ ALWAYS do this:**
```bash
# Use environment variables
export TF_VAR_cloudflare_api_token="your-token"
export TF_VAR_vercel_api_token="your-token"
export AWS_PROFILE="your-profile"

terraform apply
```

**✅ Or use secure secret management:**
- AWS Secrets Manager
- HashiCorp Vault
- Terraform Cloud with encrypted variables
- GitHub Actions secrets (for CI/CD)

### 2. State File Security

Terraform state files contain sensitive information. Protect them:

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "dns/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # Enable encryption at rest
    dynamodb_table = "terraform-locks"  # Enable state locking
  }
}
```

**Important:**
- Enable encryption at rest for state storage
- Use state locking to prevent concurrent modifications
- Restrict access to state storage (IAM policies, bucket policies)
- Never commit `.tfstate` files to version control

### 3. Minimum IAM Permissions

#### AWS Route53
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:CreateHostedZone",
        "route53:DeleteHostedZone",
        "route53:GetHostedZone",
        "route53:ListHostedZones",
        "route53:ChangeResourceRecordSets",
        "route53:ListResourceRecordSets",
        "route53:GetChange"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Cloudflare API Token
Minimum permissions:
- Zone - DNS - Edit
- Zone - Zone - Read

#### Vercel Token
- DNS write access only (avoid full account access)

### 4. DNS Security Considerations

#### Prevent DNS Hijacking
- Use strong API credentials
- Enable 2FA on provider accounts
- Regularly rotate API tokens
- Monitor DNS changes for unauthorized modifications

#### DNSSEC
While this module creates DNS records, DNSSEC must be configured manually:
- AWS Route53: Enable DNSSEC signing in the console
- Cloudflare: Enable DNSSEC in zone settings
- Vercel: Check Vercel documentation for DNSSEC support

#### CAA Records
Add Certificate Authority Authorization records:
```json
{
  "name": "",
  "type": "CAA",
  "value": "0 issue \"letsencrypt.org\"",
  "ttl": 300
}
```

### 5. Code Review and Validation

- Always run `terraform plan` before `terraform apply`
- Review all changes in CI/CD pipelines
- Use the built-in validation: `enable_validation = true`
- Validate JSON configurations: `./scripts/validate-config.py`

### 6. Network Security

- Use secure connections (HTTPS) for all provider APIs
- Avoid running Terraform from untrusted networks
- Use VPNs or bastion hosts for sensitive operations

### 7. Audit Logging

Enable logging for all providers:
- **AWS**: CloudTrail for Route53 API calls
- **Cloudflare**: Audit logs in dashboard
- **Vercel**: Activity logs in team settings

### 8. Git Security

Add to `.gitignore`:
```
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
.terraform/
secrets.auto.tfvars
.env
```

### 9. CI/CD Security

For GitHub Actions:
```yaml
env:
  # Use repository secrets
  TF_VAR_cloudflare_api_token: ${{ secrets.CLOUDFLARE_TOKEN }}
  TF_VAR_vercel_api_token: ${{ secrets.VERCEL_TOKEN }}
```

Never log sensitive values:
```yaml
- name: Terraform Plan
  run: terraform plan -no-color
  # Don't use -var="token=$TOKEN" as it may appear in logs
```

## Known Security Considerations

### Provider API Tokens

API tokens used by this module have the following access levels:
- **AWS**: Full Route53 access (consider using IAM roles instead of keys)
- **Cloudflare**: Zone-level DNS management
- **Vercel**: DNS record management

**Recommendation**: Use separate tokens/credentials for different environments (prod, staging, dev).

### State File Exposure

Terraform state files may contain:
- Zone IDs
- Nameserver information
- Record values (including sensitive TXT records)
- Provider configuration metadata

**Mitigation**: Encrypt state files and restrict access.

### DNS Cache Poisoning

While this module doesn't directly prevent DNS cache poisoning, follow these practices:
- Use DNSSEC when possible
- Monitor for unauthorized DNS changes
- Use short TTLs during migrations, then increase for stability
- Implement SPF, DKIM, and DMARC for email records

## Vulnerability Disclosure Timeline

1. **Day 0**: Vulnerability reported
2. **Day 1-2**: Acknowledge receipt and begin investigation
3. **Day 7**: Provide status update to reporter
4. **Day 14**: Second status update
5. **Day 30**: Target resolution date
6. **Day 30+**: Coordinate public disclosure with reporter
7. **Release**: Publish security advisory and patched version

## Security Updates

Security updates will be published:
- As GitHub Security Advisories
- In the CHANGELOG with `[SECURITY]` prefix
- Via GitHub Releases
- Mentioned in README if critical

## Attribution

We believe in recognizing security researchers. With your permission, we will:
- Credit you in the security advisory
- Mention you in CHANGELOG and release notes
- Add you to SECURITY.md Hall of Fame (if you wish)

## Contact

For security concerns: Use GitHub's "Report a vulnerability" feature or contact the repository maintainers.

For general questions: Use GitHub Issues or Discussions.

---

**Last Updated**: 2025-10-24
**Module Version**: 1.0.0
