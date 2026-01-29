# -------------------------------------
# Inventory S3 bucket policy
# -------------------------------------

# Required policy statement that allows S3 to write inventory reports
data "aws_iam_policy_document" "required" {
  statement {
    sid    = "AllowS3InventoryToWriteReports"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = ["${local.inventory_bucket_arn}/*"]
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
}

# Additional user-provided policy statements converted from object format
# aws_iam_policy_document properly handles optional fields and avoids null values in JSON output
data "aws_iam_policy_document" "additional" {
  count = length(var.additional_bucket_policy_statements) > 0 ? 1 : 0

  # Convert each statement from object format to aws_iam_policy_document format
  source_policy_documents = [
    jsonencode({
      Version = "2012-10-17"
      # Filter out null values from each statement before encoding
      Statement = [
        for stmt in var.additional_bucket_policy_statements : {
          for k, v in stmt : k => v if v != null
        }
      ]
    })
  ]
}

# Combine required and additional policies
data "aws_iam_policy_document" "combined" {
  source_policy_documents = concat(
    [data.aws_iam_policy_document.required.json],
    length(var.additional_bucket_policy_statements) > 0 ? [data.aws_iam_policy_document.additional[0].json] : []
  )
}

locals {
  # JSON policy document with ONLY the required statements
  # Useful for merging with custom policies via source_policy_documents
  required_policy_document = data.aws_iam_policy_document.required.json

  # Complete policy document with all statements (required + additional)
  policy_document = data.aws_iam_policy_document.combined.json
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.attach_bucket_policy ? 1 : 0
  bucket = var.inventory_bucket_name
  policy = local.policy_document
}
