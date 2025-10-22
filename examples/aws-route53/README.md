# Example: AWS Route53

This example shows how to use the DNS module with AWS Route53.

## Prerequisites

1. AWS account with Route53 permissions
2. AWS CLI configured or credentials available
3. Terraform >= 1.3.0

## Configuration

### Option 1: Use JSON file (recommended)

1. Edit `dns-config.json` with your domains and records
2. Execute:

```bash
terraform init
terraform plan
terraform apply
```

### Option 2: Use Terraform variables

1. Edit `main.tf` and uncomment the `module "dns_from_vars"` block
2. Comment out the `module "dns_from_json"` block
3. Execute Terraform:

```bash
terraform init
terraform plan
terraform apply
```

## Configure AWS Credentials

### Method 1: AWS CLI Profile

```bash
export AWS_PROFILE=my-profile
terraform apply
```

### Method 2: Environment Variables

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
terraform apply
```

### Method 3: IAM Roles (Production)

If you are running on EC2/ECS/Lambda, use IAM roles instead of credentials.

## AWS Route53 Features

### Alias Records

AWS Route53 supports alias records for AWS resources (CloudFront, ELB, S3, etc.):

```json
{
  "name": "cdn",
  "type": "A",
  "value": "",
  "alias": {
    "name": "d111111abcdef8.cloudfront.net",
    "zone_id": "Z2FDTNDATAQYW2",
    "evaluate_target_health": false
  }
}
```

### Delegation Sets

To reuse the same nameservers across multiple zones:

```bash
# Create delegation set
aws route53 create-reusable-delegation-set --caller-reference "my-delegation-set"

# Use in the module
terraform apply -var="aws_delegation_set_id=N1PA6795SAMPLE"
```

## Outputs

After running `terraform apply`, you will get:

- **name_servers**: Nameservers to configure in your registrar
- **zone_ids**: IDs of the Route53 zones
- **zones_info**: Complete information for each zone

## Next Steps

1. Configure the nameservers in your domain registrar
2. Wait for DNS propagation (up to 48 hours, usually minutes)
3. Verify with: `dig NS example.com`
4. Verify records: `dig www.example.com`

## Cleanup

```bash
terraform destroy
```

**Note**: If `aws_force_destroy = false`, you must manually delete all records before destroying the zone.
