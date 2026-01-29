
# -------------------------------------------------
# S3 bucket for inventories of ECS backups
# -------------------------------------------------

# Default bucket policy statements
data "aws_iam_policy_document" "default_inventory_bucket_policy" {
  # Allow S3 service to create inventory objects in the bucket
  # This is necessary for the S3 Inventory feature to work correctly.
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.inventory_bucket_name}/*",
    ]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  # Prevent objects in the bucket from being deleted or overwritten
  # Deny statements in a bucket policy don't prevent the expiration of the objects
  # defined in a lifecycle rule. Lifecycle actions (such as transitions or expirations)
  # don't use the S3 DeleteObject operation. Instead, S3 Lifecycle actions are performed
  # by using internal S3 endpoints.
  #
  # https://docs.aws.amazon.com/AmazonS3/latest/userguide/troubleshoot-lifecycle.html#troubleshoot-lifecycle-6

  # Prevent all changes to non-current objects
  statement {
    effect = "Deny"
    actions = [
      "s3:DeleteObjectVersion*",
      "s3:PutObjectVersion*",
    ]
    resources = [
      "arn:aws:s3:::${var.inventory_bucket_name}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  # S3 best practice: Deny insecure transport (enforce HTTPS)
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.inventory_bucket_name}",
      "arn:aws:s3:::${var.inventory_bucket_name}/*",
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Merged bucket policy (default + custom)
data "aws_iam_policy_document" "inventory_bucket_policy" {
  # Include default policy statements if enabled
  source_policy_documents = concat(
    var.attach_default_inventory_bucket_policy ? [data.aws_iam_policy_document.default_inventory_bucket_policy.json] : [],
    var.inventory_bucket_policy_statements != null ? [var.inventory_bucket_policy_statements] : []
  )
}

module "inventory_bucket" {
  count = var.create_inventory_bucket ? 1 : 0

  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.6.0"

  bucket = var.inventory_bucket_name

  server_side_encryption_configuration = var.inventory_bucket_encryption_config

  versioning = {
    enabled = true
  }

  attach_policy = var.attach_default_inventory_bucket_policy || var.inventory_bucket_policy_statements != null
  policy = (
    var.attach_default_inventory_bucket_policy || var.inventory_bucket_policy_statements != null
    ? data.aws_iam_policy_document.inventory_bucket_policy.json
    : null
  )

  # Note: Object Lock configuration can be enabled only on new buckets
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object_lock_configuration
  object_lock_enabled = var.inventory_bucket_object_lock_retention_days != null # Forces new resource

  # TODO make dynamic
  object_lock_configuration = {
    rule = {
      default_retention = {
        # https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lock.html#object-lock-retention-modes

        # Consider using Governance mode if you want to protect objects from being deleted
        # by most users during a pre-defined retention period, but at the same time want
        # some users with special permissions to have the flexibility to alter the
        # retention settings or delete the objects.
        mode = var.inventory_bucket_object_lock_mode

        days = var.inventory_bucket_object_lock_retention_days
      }
    }
  }

  lifecycle_rule = (
    var.apply_default_inventory_lifecyle_rules
    ? local.inventory_default_lifecycle_rules
    : var.inventory_bucket_lifecycle_rules
  )
}
