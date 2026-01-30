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
