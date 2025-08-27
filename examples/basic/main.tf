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
# Example
#--------------------------------------------------------------------------------------

module "inventory" {
  # Uncomment and update as needed
  # source  = "<your_module_url>"
  # version = "~> 1.0"
  source = "../../"

  # ------- Required module parameters ---------
  inventory_bucket_name   = "${local.random_name}-inventory"
  inventory_database_name = "${local.random_name}-inventory"

  # ------ Optional module parameters ----------
  # List of S3 buckets
  source_bucket_names = [
    aws_s3_bucket.example_data_1.bucket,
    aws_s3_bucket.example_data_2.bucket
  ]

  # Inventory bucket settings
  inventory_bucket_encryption_config = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "aws:kms"
      }
    }
  }
}
