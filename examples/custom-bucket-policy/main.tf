#--------------------------------------------------------------------------------------
# Naming
#--------------------------------------------------------------------------------------

# Generate unique naming for resources
resource "random_integer" "naming" {
  min = 100000
  max = 999999
}

locals {
  random_name = "example-custom-policy-${random_integer.naming.id}"
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
# Example - With custom bucket policy
#--------------------------------------------------------------------------------------

module "inventory" {
  # Uncomment and update as needed
  # source  = "<your_module_url>"
  # version = "~> 2.0"
  source = "../../"

  # ------- Required module parameters ---------
  inventory_bucket_name   = aws_s3_bucket.s3_inventory_bucket.bucket
  inventory_database_name = aws_glue_catalog_database.s3_inventory.name

  # IMPORTANT: Disable the module's automatic bucket policy attachment
  # We're applying a custom policy ourselves (which includes the required default policy)
  # Only one bucket policy can exist per S3 bucket
  attach_bucket_policy = false

  # ------ Optional module parameters ----------
  source_bucket_names = [
    aws_s3_bucket.example_data.bucket
  ]
}

# Custom bucket policy that INCLUDES the required default policy
# The default policy is REQUIRED for S3 to write inventory files to the bucket
data "aws_iam_policy_document" "custom_inventory_bucket_policy" {
  # IMPORTANT: Include the module's default policy
  # This policy allows the S3 service to write inventory files
  # Without it, S3 inventory will not work
  source_policy_documents = [
    module.inventory.required_bucket_policy
  ]

  # Now add your additional custom policy statements
  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.s3_inventory_bucket.arn}/*"
    ]
    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["aws:kms"]
    }
  }

  # Prevent deletion of non-current object versions
  statement {
    sid    = "DenyDeleteNonCurrentVersions"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:DeleteObjectVersion"
    ]
    resources = [
      "${aws_s3_bucket.s3_inventory_bucket.arn}/*"
    ]
  }
}

# Apply the combined bucket policy (default + custom statements)
resource "aws_s3_bucket_policy" "custom_inventory_bucket_policy" {
  bucket = aws_s3_bucket.s3_inventory_bucket.id
  policy = data.aws_iam_policy_document.custom_inventory_bucket_policy.json
}
