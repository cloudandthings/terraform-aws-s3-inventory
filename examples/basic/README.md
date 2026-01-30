# Overview

This is the basic example showing the simplest usage of the module.

## Key Features

- Creates the inventory S3 bucket and Glue database externally
- Uses the **default bucket policy** (automatically attached by the module)
- The bucket policy allows the S3 service to write inventory files - this is required for S3 inventory to work
- Configures inventory for two example data buckets

# Generated terraform-docs
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
  random_name = "example-basic-${random_integer.naming.id}"
}

#--------------------------------------------------------------------------------------
# Supporting resources
#--------------------------------------------------------------------------------------
resource "aws_s3_bucket" "example_data_1" {
  bucket = "${local.random_name}-data-1"
}
resource "aws_s3_bucket_public_access_block" "example_data_1" {
  bucket                  = aws_s3_bucket.example_data_1.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "example_data_1" {
  bucket = aws_s3_bucket.example_data_1.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_s3_bucket" "example_data_2" {
  bucket = "${local.random_name}-data-2"
}
resource "aws_s3_bucket_public_access_block" "example_data_2" {
  bucket                  = aws_s3_bucket.example_data_2.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "example_data_2" {
  bucket = aws_s3_bucket.example_data_2.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

#--------------------------------------------------------------------------------------
# Inventory bucket and Glue database
#--------------------------------------------------------------------------------------
resource "aws_s3_bucket" "s3_inventory_bucket" {
  bucket = "${local.random_name}-s3-inventory"
}
resource "aws_s3_bucket_public_access_block" "s3_inventory_bucket" {
  bucket                  = aws_s3_bucket.s3_inventory_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_inventory_bucket" {
  bucket = aws_s3_bucket.s3_inventory_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}

resource "aws_glue_catalog_database" "s3_inventory" {
  name = "${local.random_name}-s3-inventory"
}

#--------------------------------------------------------------------------------------
# Example
#--------------------------------------------------------------------------------------

module "inventory" {
  # Uncomment and update as needed
  # source  = "<your_module_url>"
  # version = "~> 2.0"
  source = "../../"

  # ------- Required module parameters ---------
  inventory_bucket_name   = aws_s3_bucket.s3_inventory_bucket.bucket
  inventory_database_name = aws_glue_catalog_database.s3_inventory.name

  # ------ Optional module parameters ----------
  # List of S3 buckets
  source_bucket_names = [
    aws_s3_bucket.example_data_1.bucket,
    aws_s3_bucket.example_data_2.bucket
  ]

  # Create views for querying inventory data
  union_all_view_name    = "all_inventories"    # Union ALL partitions (complete historical data)
  union_latest_view_name = "latest_inventories" # Union LATEST partition per bucket (current state, more efficient)

  # The module will automatically attach the required bucket policy
  # that allows the S3 service to write inventory files
  # attach_bucket_policy = true  # This is the default
}
```
----

## Documentation

----
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_profile"></a> [aws\_profile](#input\_aws\_profile) | AWS profile | `string` | `null` | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region | `string` | `null` | no |

----
### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_inventory"></a> [inventory](#module\_inventory) | ../../ | n/a |

----
### Outputs

| Name | Description |
|------|-------------|
| <a name="output_module_example"></a> [module\_example](#output\_module\_example) | module.inventory |

----
### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |
| <a name="provider_random"></a> [random](#provider\_random) | ~> 3.4 |

----
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.4 |

----
### Resources

| Name | Type |
|------|------|
| [aws_glue_catalog_database.s3_inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_s3_bucket.example_data_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.example_data_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.s3_inventory_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_public_access_block.example_data_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.example_data_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.s3_inventory_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.example_data_1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.example_data_2](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.s3_inventory_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [random_integer.naming](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) | resource |

----
<!-- END_TF_DOCS -->
