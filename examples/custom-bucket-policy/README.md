# Example: Custom Bucket Policy

This example demonstrates how to add custom policy statements to the S3 inventory bucket while retaining the default policy statements.

## Features Demonstrated

- Adding custom IAM policy statements to the inventory bucket using JSON
- Merging custom statements with default policy statements
- Granting specific IAM roles access to inventory data
- Using `aws_iam_policy_document` data source to generate policy JSON

## Usage

The key feature shown in this example is the `inventory_bucket_policy_statements` variable with JSON input:

```hcl
# Create a custom policy document
data "aws_iam_policy_document" "custom_policy" {
  statement {
    sid    = "AllowInventoryReaderRole"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.inventory_bucket_name}",
      "arn:aws:s3:::${local.inventory_bucket_name}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.inventory_reader.arn]
    }
  }
}

# Pass the JSON to the module
module "s3_inventory" {
  # ...
  inventory_bucket_policy_statements = data.aws_iam_policy_document.custom_policy.json
}
```

## Default Policy Statements

When using custom statements, the module will automatically include:
1. S3 service permissions to write inventory reports
2. Protection against deletion/modification of non-current object versions
3. Enforcement of HTTPS/secure transport

## Outputs

The example provides outputs that show:
- `module_inventory`: Complete module outputs including the default and merged policy documents
  - Access policy documents via `module_inventory.default_inventory_bucket_policy_json` and `module_inventory.inventory_bucket_policy_json`
- `inventory_reader_role_arn`: ARN of the example IAM role

## Testing

```bash
terraform init
terraform plan
terraform apply
```

After applying, you can verify the bucket policy using the module output:

```bash
# View the complete bucket policy
terraform output -json module_inventory | jq -r '.inventory_bucket_policy_json | fromjson'

# Or directly query AWS
aws s3api get-bucket-policy --bucket <your-inventory-bucket-name> | jq -r '.Policy | fromjson'
```

<!-- BEGIN_TF_DOCS -->
----
## main.tf
```hcl
#--------------------------------------------------------------------------------------
# Naming
#--------------------------------------------------------------------------------------

# Generate unique naming for resources
resource "random_integer" "naming" {
  min = 100000
  max = 999999
}

locals {
  random_name           = "example-custom-policy-${random_integer.naming.id}"
  inventory_bucket_name = "${local.random_name}-inventory"
}

#--------------------------------------------------------------------------------------
# Supporting resources
#--------------------------------------------------------------------------------------
resource "aws_s3_bucket" "example_data" {
  bucket = "${local.random_name}-data"
}
resource "aws_s3_bucket_public_access_block" "example_data" {
  bucket                  = aws_s3_bucket.example_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "example_data" {
  bucket = aws_s3_bucket.example_data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

# Example IAM role that needs access to inventory bucket
resource "aws_iam_role" "inventory_reader" {
  name = "${local.random_name}-inventory-reader"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

#--------------------------------------------------------------------------------------
# Example - Custom Bucket Policy Statements
#--------------------------------------------------------------------------------------

# Create a custom policy document with additional statements
data "aws_iam_policy_document" "custom_policy" {
  statement {
    sid    = "AllowInventoryReaderRole"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.inventory_bucket_name}",
      "arn:aws:s3:::${local.inventory_bucket_name}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.inventory_reader.arn]
    }
  }
}

module "inventory" {
  # Uncomment and update as needed
  # source  = "<your_module_url>"
  # version = "~> 1.0"
  source = "../../"

  # ------- Required module parameters ---------
  inventory_bucket_name   = local.inventory_bucket_name
  inventory_database_name = "${local.random_name}-inventory"

  # ------ Optional module parameters ----------
  # List of S3 buckets
  source_bucket_names = [
    aws_s3_bucket.example_data.bucket,
  ]

  # Inventory bucket settings
  inventory_bucket_encryption_config = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }

  # Custom bucket policy statements (as JSON from aws_iam_policy_document)
  # This will be merged with the default policy statements
  inventory_bucket_policy_statements = data.aws_iam_policy_document.custom_policy.json
}
```
----

## Documentation

----
### Inputs

No inputs.

----
### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_inventory"></a> [inventory](#module\_inventory) | ../../ | n/a |

----
### Outputs

| Name | Description |
|------|-------------|
| <a name="output_inventory_reader_role_arn"></a> [inventory\_reader\_role\_arn](#output\_inventory\_reader\_role\_arn) | ARN of the example IAM role that can read inventory data |
| <a name="output_module_inventory"></a> [module\_inventory](#output\_module\_inventory) | Complete module outputs including bucket and database information |

----
### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5, < 7 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.4 |

----
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5, < 7 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |

----
### Resources

| Name | Type |
|------|------|
| [aws_iam_role.inventory_reader](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_s3_bucket.example_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.example_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.example_data](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [random_integer.naming](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |
| [aws_iam_policy_document.custom_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

----
<!-- END_TF_DOCS -->
