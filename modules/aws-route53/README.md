# AWS Route53 Submodule

This submodule manages DNS zones and records in AWS Route53.

## Features

- Creates Route53 hosted zones
- Manages standard DNS records (A, AAAA, CNAME, MX, TXT, etc.)
- Supports AWS-specific alias records
- Delegation set support for consistent nameservers
- Automatic handling of MX record priorities
- Allows overwriting auto-created NS and SOA records

## Usage

This module is designed to be called by the parent DNS module and should not typically be used directly. However, if you need to use it standalone:

```hcl
module "aws_route53" {
  source = "./modules/aws-route53"

  zones = {
    example = {
      domain  = "example.com"
      comment = "Example domain"
      tags = {
        Environment = "production"
      }
      records = [
        {
          name     = "www"
          type     = "A"
          value    = "192.0.2.1"
          ttl      = 300
          priority = null
          alias    = null
        }
      ]
      zone_config = {
        force_destroy     = false
        delegation_set_id = null
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
- `comment` (string): Zone comment
- `tags` (map): Resource tags
- `records` (list): List of DNS records
- `zone_config` (object): Zone-specific configuration
  - `force_destroy` (bool): Allow zone deletion with records
  - `delegation_set_id` (string): Optional delegation set ID

Each record in `records` must have:

- `name` (string): Record name (subdomain or empty for apex)
- `type` (string): DNS record type
- `value` (string): Record value
- `ttl` (number): Time to live in seconds
- `priority` (number, optional): For MX/SRV records
- `alias` (object, optional): Alias record configuration
  - `name` (string): Target resource domain name
  - `zone_id` (string): Target zone ID
  - `evaluate_target_health` (bool): Health check evaluation

## Outputs

### zone_ids

IDs of the created Route53 zones.

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
- `arn`: Zone ARN

### record_fqdns

Fully qualified domain names of all created records.

**Type**: `map(string)`

## Alias Records

AWS Route53 alias records allow you to route traffic to AWS resources without needing to know their IP addresses. They work similarly to CNAME records but can be created for the zone apex.

### Supported Targets

- CloudFront distributions
- Elastic Load Balancers (ALB, NLB, CLB)
- S3 website endpoints
- API Gateway
- Elastic Beanstalk environments
- Other Route53 records in the same hosted zone

### Example

```hcl
{
  name = "cdn"
  type = "A"
  value = ""  # Not used for alias records
  alias = {
    name                   = "d111111abcdef8.cloudfront.net"
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFront zone ID
    evaluate_target_health = false
  }
}
```

### Common Zone IDs

- CloudFront: `Z2FDTNDATAQYW2`
- S3 website (us-east-1): `Z3AQBSTGFYJSTF`
- See [AWS documentation](https://docs.aws.amazon.com/general/latest/gr/r53.html) for complete list

## Record Types

### Supported Types

- **A**: IPv4 address
- **AAAA**: IPv6 address
- **CAA**: Certificate Authority Authorization
- **CNAME**: Canonical name
- **MX**: Mail exchange
- **NAPTR**: Name Authority Pointer
- **NS**: Name server
- **PTR**: Pointer
- **SOA**: Start of Authority
- **SPF**: Sender Policy Framework
- **SRV**: Service locator
- **TXT**: Text

### MX Records

MX records require a priority. The module automatically formats them correctly:

```hcl
{
  name     = ""
  type     = "MX"
  value    = "mail.example.com"
  priority = 10
  ttl      = 300
}
```

This creates: `10 mail.example.com`

## Delegation Sets

Delegation sets allow you to use the same set of nameservers across multiple hosted zones.

### Create a Delegation Set

```bash
aws route53 create-reusable-delegation-set \
  --caller-reference "my-delegation-set-$(date +%s)"
```

### Use in Module

```hcl
zone_config = {
  delegation_set_id = "N1PA6795SAMPLE"
  force_destroy     = false
}
```

## Resource Naming

Resources are created with the following naming pattern:

- Zones: `aws_route53_zone.this["zone_key"]`
- Standard records: `aws_route53_record.standard["zone_key--name--type--index"]`
- Alias records: `aws_route53_record.alias["zone_key--name--type--index"]`

## Permissions Required

The AWS credentials used must have the following permissions:

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

## Notes

- NS and SOA records are automatically created by AWS and can be overwritten using `allow_overwrite = true`
- Alias records cannot have a TTL (AWS manages this automatically)
- Zone deletion requires `force_destroy = true` if records exist
- Name server propagation can take up to 48 hours

## Resources

- [AWS Route53 Documentation](https://docs.aws.amazon.com/route53/)
- [Terraform AWS Provider - Route53 Zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_zone)
- [Terraform AWS Provider - Route53 Record](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record)
