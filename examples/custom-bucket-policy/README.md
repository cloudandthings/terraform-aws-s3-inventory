# Example: Custom Bucket Policy

This example demonstrates how to add custom policy statements to the S3 inventory bucket while retaining the default policy statements.

## Features Demonstrated

- Adding custom IAM policy statements to the inventory bucket
- Merging custom statements with default policy statements
- Granting specific IAM roles access to inventory data
- Viewing both the default and complete (merged) bucket policies via outputs

## Usage

The key feature shown in this example is the `inventory_bucket_policy_statements` variable:

```hcl
inventory_bucket_policy_statements = [
  {
    sid    = "AllowInventoryReaderRole"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.random_name}-inventory",
      "arn:aws:s3:::${local.random_name}-inventory/*"
    ]
    principals = [{
      type        = "AWS"
      identifiers = [aws_iam_role.inventory_reader.arn]
    }]
  }
]
```

## Default Policy Statements

When using custom statements, the module will automatically include:
1. S3 service permissions to write inventory reports
2. Protection against deletion/modification of non-current object versions
3. Enforcement of HTTPS/secure transport

## Outputs

This example includes outputs that show:
- `default_policy_json`: The default bucket policy before merging
- `complete_policy_json`: The final merged policy with custom statements included

## Testing

```bash
terraform init
terraform plan
terraform apply
```

After applying, you can verify the bucket policy:

```bash
aws s3api get-bucket-policy --bucket $(terraform output -raw inventory_bucket_name) | jq -r '.Policy | fromjson'
```
