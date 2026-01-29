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
