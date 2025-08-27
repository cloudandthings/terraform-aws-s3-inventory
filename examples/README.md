# More examples

Below are some additional generated examples for reference.

### Basic Setup

```hcl
module "s3_inventory" {
  source = "github.com/your-org/terraform-aws-s3-inventory"

  inventory_bucket_name   = "acme-corp-s3-inventory"
  inventory_database_name = "s3_inventory"
  source_bucket_names     = ["data-lake", "application-logs"]
}
```

### Advanced Configuration with Security

```hcl
module "s3_inventory" {
  source = "github.com/your-org/terraform-aws-s3-inventory"

  # Core configuration
  inventory_bucket_name   = "secure-s3-inventory"
  inventory_database_name = "inventory_catalog"
  source_bucket_names     = ["sensitive-data", "compliance-logs"]

  # Security settings
  inventory_bucket_encryption_config = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"
      }
    }
  }

  # Object lock for compliance
  inventory_bucket_object_lock_retention_days = 30
  inventory_bucket_object_lock_mode          = "COMPLIANCE"

  # Access permissions
  database_admin_principals = [
    "arn:aws:iam::123456789012:role/DataEngineers"
  ]

  database_read_principals = [
    "arn:aws:iam::123456789012:role/DataAnalysts",
    "arn:aws:iam::123456789012:role/AuditTeam"
  ]

  # Custom inventory fields
  inventory_optional_fields = [
    "Size",
    "LastModifiedDate",
    "StorageClass",
    "EncryptionStatus"
  ]

  # Union view for cross-bucket analysis
  union_view_name = "consolidated_inventory"
}
```

### Lifecycle Management

```hcl
module "s3_inventory" {
  source = "github.com/your-org/terraform-aws-s3-inventory"

  inventory_bucket_name   = "cost-optimized-inventory"
  inventory_database_name = "inventory_db"
  source_bucket_names     = ["production-data"]

  # Custom lifecycle rules
  inventory_bucket_lifecycle_rules = [
    {
      id     = "inventory_retention"
      status = "Enabled"

      transition = [
        {
          days          = 30
          storage_class = "STANDARD_IA"
        },
        {
          days          = 90
          storage_class = "GLACIER"
        }
      ]

      expiration = {
        days = 365
      }
    }
  ]
}
```
