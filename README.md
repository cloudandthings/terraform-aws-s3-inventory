# Terraform AWS S3 Inventory Module

A comprehensive Terraform module for managing AWS S3 inventory configurations, including automated inventory reports, Glue catalog integration, and Athena querying capabilities.

## ⚠️ Breaking Changes in v2.0.0

**The variable `var.union_view_name` has been renamed to `var.union_all_view_name`**

If you were using `var.union_view_name`, then use `var.union_all_view_name` instead.

**This module no longer creates the S3 inventory bucket or Glue database**

If you were using the default behavior (`create_inventory_bucket = true` and `create_inventory_database = true`),
these resources are no longer created by the module. They must now be created externally and passed to the module. You must:

1. **Create the S3 bucket externally** before calling this module
2. **Create the Glue database externally** before calling this module
3. **Remove the following variables** from your module configuration (they no longer exist):
   - `create_inventory_bucket`
   - `create_inventory_database`
   - `apply_default_inventory_lifecyle_rules`
   - `inventory_bucket_lifecycle_rules`
   - `inventory_bucket_object_lock_retention_days`
   - `inventory_bucket_object_lock_mode`
   - `inventory_bucket_encryption_config`

See the [examples](https://github.com/cloudandthings/terraform-aws-s3-inventory/tree/main/examples/) for updated usage patterns.

**This module no longer creates additional S3 resources**

The following resources are no longer created by the module because it no longer creates the S3 bucket. These resources should be created externally (if required):

- Bucket lifecycle rules
- Bucket encryption
- Bucket object lock configuration

This change allows the user a lot more flexibility to manage the S3 bucket in their own environment.

## Features

- **S3 Inventory Management**: Creates and configures S3 inventory reports for multiple source buckets
- **Glue Catalog Integration**: Sets up Glue tables for querying inventory data (database must be provided)
- **Union All View**: Optional view that unions ALL inventory partitions from all buckets (complete historical data)
- **Union Latest View**: Optional view that unions only the LATEST partition from each bucket (current state, more efficient)
- **Security & Compliance**: Optional default bucket policy and configurable LakeFormation permissions
- **Flexible Architecture**: Bring your own S3 bucket and Glue database with custom configurations

Many features are optional and can be enabled/disabled as required.

----

## S3 Bucket Policy Requirement

**Important:** The inventory bucket requires a specific bucket policy to allow the AWS S3 service to write inventory files. This policy is **required** for S3 inventory to function.

The module provides two approaches:

1. **Default (Recommended):** The module automatically generates and attaches the required bucket policy
   - Set `attach_bucket_policy = true` (this is the default)
   - The module handles everything for you

2. **Custom Policy:** If you need additional policy statements beyond the default
   - You could provide them using `additional_bucket_policy_statements`, and the module will include them, or:

   - Set `attach_bucket_policy = false`
   - Use the `required_bucket_policy` output to get the required policy
   - Merge it with your custom statements using `source_policy_documents`
   - Apply the combined policy yourself

**Note:** Only one bucket policy can exist per S3 bucket. For S3 inventory to be able to write to the destination bucket, the bucket policy must include the module's required policy statements.

----

## Quick Start

```hcl
# First, create the S3 bucket for inventory storage
resource "aws_s3_bucket" "inventory" {
  bucket = "my-company-s3-inventory"
}

# Create the Glue database for inventory tables
resource "aws_glue_catalog_database" "inventory" {
  name = "s3_inventory_db"
}

# Now configure the S3 inventory module
module "s3_inventory" {
  source  = "cloudandthings/terraform-aws-s3-inventory/aws"
  version = "~> 2.0"

  # Required: Reference the externally created resources
  inventory_bucket_name   = aws_s3_bucket.inventory.bucket
  inventory_database_name = aws_glue_catalog_database.inventory.name

  # Source buckets to inventory
  source_bucket_names = [
    "my-app-data-bucket",
    "my-logs-bucket",
    "my-backup-bucket"
  ]

  # Optional: Union all view - all inventory partitions (complete historical data)
  union_all_view_name    = "${local.random_name}_union_all_view"

  # Optional: Union latest view - latest partition only (current state, more efficient)
  union_latest_view_name = "${local.random_name}_union_latest_view"

  # Optional: Add LakeFormation permissions
  # database_admin_principals = [...]
  # database_read_principals = [...]

  # By default, the module will attach the required bucket policy automatically
  # attach_bucket_policy = true  # This is the default
}
```


----
## Usage

See examples dropdown on Terraform Cloud, or [browse the GitHub repo](https://github.com/cloudandthings/terraform-aws-s3-inventory/tree/main/examples/).

----

## Querying Your Inventory Data

Once deployed, you can query your S3 inventory data using Amazon Athena.

### Querying Individual Buckets

Each source bucket has its own Glue table with all historical partitions:

```sql
SELECT bucket, key, size, last_modified_date, storage_class
FROM s3_inventory_db.my_app_data_bucket
WHERE dt = '2024-08-29-00-00'
ORDER BY size DESC
LIMIT 100;
```

### Querying Current State (Union Latest View)

**Recommended for most use cases** - the union latest view queries only the most recent partition from each bucket:

```sql
-- Get current object count and total size per bucket
SELECT bucket,
       COUNT(*) as object_count,
       SUM(size) as total_size,
       AVG(size) as avg_size
FROM s3_inventory_db.union_latest_view
GROUP BY bucket
ORDER BY total_size DESC;

-- Find largest objects across all buckets
SELECT bucket, key, size, storage_class, last_modified_date
FROM s3_inventory_db.union_latest_view
ORDER BY size DESC
LIMIT 100;
```

#### How the Latest View Works

The union latest view is designed for performance and queries **yesterday's data** rather than dynamically finding the maximum partition for each bucket. This means:

- **Only yesterday's inventory data is included** - The view filters for partitions from yesterday (`date_add('day', -1, CURRENT_DATE)`)
- **Stale inventories won't appear** - If a bucket's inventory hasn't run recently, it won't show up in the latest view
- **For stale data, use the union all view** - To see historical or stale inventories, query the union all view which includes all partitions

**Why this design?** Querying the maximum partition of a projected table in Amazon Athena is inefficient and can result in slow query performance and higher costs. By using yesterday's data, the view provides a fast, cost-effective way to get a recent snapshot of your S3 inventory across all buckets.

If you need to access all inventory data regardless of age, use the union all view instead (see below).

### Querying Historical Data (Union All View)

The union all view includes all inventory partitions from all buckets - use this for trend analysis:

```sql
-- Track storage growth over time
SELECT dt, bucket, COUNT(*) as object_count, SUM(size) as total_size
FROM s3_inventory_db.union_all_view
WHERE dt >= '2024-08-01-00-00'
GROUP BY dt, bucket
ORDER BY dt DESC, total_size DESC;
```

### Performance Tips

- **Use the “latest inventories” view for current state queries** – the view configured via `var.union_latest_view_name`; this scans only the most recent partition per bucket (faster and cheaper)
- **Use the “all inventories” view for trend analysis** – the view configured via `var.union_all_view_name`; this includes all historical partitions when you need time-series data
- **Query individual bucket tables** when working with a single bucket and need partition filtering
- **Always use column projection** - select only needed columns instead of `SELECT *`
- **Apply partition filters** on individual tables: `WHERE dt >= 'YYYY-MM-DD-HH-MM'`

----

## Important Considerations

### Athena Partition Date Projection

As of 2025, Amazon Athena does not properly support dynamic range projection with the S3 inventory partitioning scheme. When using a dynamic range like `"NOW-3MONTHS,NOW"` with this module, the Glue tables will return zero rows.

To work around this limitation, this Terraform module defaults to using the beginning of the previous year as the start date. The year is calculated based on when the Terraform plan runs. For example, if today is `2025-08-25`, the date range will be defaulted to `"2024-01-01-00-00,NOW"`.

**Important:** This approach causes Terraform state drift annually when the year changes.

### Workaround

To avoid state drift, provide a fixed start date for partition projection, such as:

`athena_projection_dt_range = "2025-08-01-00-00,NOW"`

Choose your start date based on either:
- Your specific requirements
- The date when your S3 inventories were first deployed


### Costs

- S3 inventory reports are charged per million objects listed
- Additional S3 storage costs for inventory files
- Athena charges apply when querying the data
- Consider lifecycle rules to manage long-term storage costs

----

## Contributing

Direct contributions are welcome.

See [`CONTRIBUTING.md`](https://github.com/cloudandthings/terraform-aws-s3-inventory/tree/main/.github/CONTRIBUTING.md) for further information.


----
## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

----

*This module was created from [terraform-aws-template](https://github.com/cloudandthings/terraform-aws-template)*


<!-- BEGIN_TF_DOCS -->
----
## Documentation

----
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_bucket_policy_statements"></a> [additional\_bucket\_policy\_statements](#input\_additional\_bucket\_policy\_statements) | Additional IAM policy statements to include in the bucket policy (will be merged with module's statements) | <pre>list(object({<br/>    Sid       = optional(string)<br/>    Effect    = string<br/>    Principal = any<br/>    Action    = any<br/>    Resource  = any<br/>    Condition = optional(any)<br/>  }))</pre> | `[]` | no |
| <a name="input_athena_projection_dt_range"></a> [athena\_projection\_dt\_range](#input\_athena\_projection\_dt\_range) | Date range for Athena partition projection (format: START\_DATE,END\_DATE). If null then a value will be generated, see README for more information. | `string` | `null` | no |
| <a name="input_attach_bucket_policy"></a> [attach\_bucket\_policy](#input\_attach\_bucket\_policy) | Whether module should attach the policy to the inventory bucket.<br/>Set to false if:<br/>- You want to attach the policy yourself using the s3\_bucket\_policy\_json or s3\_bucket\_required\_policy\_json outputs<br/>- The bucket already has a policy and you want to merge them yourself<br/>- You only want to use this module to generate the policy statements | `bool` | `true` | no |
| <a name="input_database_admin_principals"></a> [database\_admin\_principals](#input\_database\_admin\_principals) | List of principal ARNs that will be allowed to manage (create, update, delete) the Glue database and its tables | `list(string)` | `[]` | no |
| <a name="input_database_read_principals"></a> [database\_read\_principals](#input\_database\_read\_principals) | List of principal ARNs that will be allowed to read from the Glue database (query tables, describe metadata) | `list(string)` | `[]` | no |
| <a name="input_enable_bucket_inventory_configs"></a> [enable\_bucket\_inventory\_configs](#input\_enable\_bucket\_inventory\_configs) | Whether to create S3 inventory configurations for the specified buckets | `bool` | `true` | no |
| <a name="input_inventory_bucket_name"></a> [inventory\_bucket\_name](#input\_inventory\_bucket\_name) | Name of the S3 inventory bucket | `string` | n/a | yes |
| <a name="input_inventory_config_encryption"></a> [inventory\_config\_encryption](#input\_inventory\_config\_encryption) | Map containing encryption settings for the S3 inventory configuration. | `any` | `{}` | no |
| <a name="input_inventory_config_frequency"></a> [inventory\_config\_frequency](#input\_inventory\_config\_frequency) | Frequency of the S3 inventory report generation | `string` | `"Daily"` | no |
| <a name="input_inventory_config_name"></a> [inventory\_config\_name](#input\_inventory\_config\_name) | Name identifier for the S3 inventory configuration | `string` | `"daily"` | no |
| <a name="input_inventory_config_object_versions"></a> [inventory\_config\_object\_versions](#input\_inventory\_config\_object\_versions) | Which object versions to include in the inventory report | `string` | `"All"` | no |
| <a name="input_inventory_database_name"></a> [inventory\_database\_name](#input\_inventory\_database\_name) | Name of the S3 inventory Glue database | `string` | n/a | yes |
| <a name="input_inventory_optional_fields"></a> [inventory\_optional\_fields](#input\_inventory\_optional\_fields) | List of optional fields to include in the S3 inventory report | `list(string)` | <pre>[<br/>  "Size",<br/>  "LastModifiedDate",<br/>  "IsMultipartUploaded",<br/>  "ReplicationStatus",<br/>  "EncryptionStatus",<br/>  "BucketKeyStatus",<br/>  "StorageClass",<br/>  "IntelligentTieringAccessTier",<br/>  "ETag",<br/>  "ChecksumAlgorithm",<br/>  "ObjectLockRetainUntilDate",<br/>  "ObjectLockMode",<br/>  "ObjectLockLegalHoldStatus",<br/>  "ObjectAccessControlList",<br/>  "ObjectOwner"<br/>]</pre> | no |
| <a name="input_inventory_tables_description"></a> [inventory\_tables\_description](#input\_inventory\_tables\_description) | Description to set on every S3 inventory Glue table. If not provided, a default will be used. | `string` | `null` | no |
| <a name="input_source_bucket_names"></a> [source\_bucket\_names](#input\_source\_bucket\_names) | List of S3 bucket names to create inventory reports for | `list(string)` | `[]` | no |
| <a name="input_union_all_view_name"></a> [union\_all\_view\_name](#input\_union\_all\_view\_name) | Name for the Athena view that unions ALL inventory partitions from all source buckets (complete historical data) | `string` | `null` | no |
| <a name="input_union_latest_view_name"></a> [union\_latest\_view\_name](#input\_union\_latest\_view\_name) | Name for the Athena view that unions the LATEST inventory partition from each source bucket (current state only, more efficient) | `string` | `null` | no |

----
### Modules

No modules.

----
### Outputs

| Name | Description |
|------|-------------|
| <a name="output_athena_projection_dt_range"></a> [athena\_projection\_dt\_range](#output\_athena\_projection\_dt\_range) | The value used for projection.dt.range on the Glue table |
| <a name="output_bucket_policy"></a> [bucket\_policy](#output\_bucket\_policy) | Complete bucket policy JSON including required statements and any additional statements. Use this to attach the policy yourself when attach\_bucket\_policy = false |
| <a name="output_required_bucket_policy"></a> [required\_bucket\_policy](#output\_required\_bucket\_policy) | Required bucket policy JSON (S3 inventory write permissions only). Use with source\_policy\_documents to merge with your custom policy |
| <a name="output_union_all_view_name"></a> [union\_all\_view\_name](#output\_union\_all\_view\_name) | Name of the created union all view (all partitions from all buckets), if enabled |
| <a name="output_union_latest_view_name"></a> [union\_latest\_view\_name](#output\_union\_latest\_view\_name) | Name of the created union latest view (latest partition from each bucket), if enabled |

----
### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 6.0 |

----
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.7 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

----
### Resources

| Name | Type |
|------|------|
| [aws_glue_catalog_table.s3_inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_glue_catalog_table.union_all_view](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_glue_catalog_table.union_latest_view](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_lakeformation_permissions.inventory_database_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_lakeformation_permissions.inventory_database_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_lakeformation_permissions.inventory_tables_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_lakeformation_permissions.inventory_tables_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_s3_bucket_inventory.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_default_tags.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/default_tags) | data source |
| [aws_iam_policy_document.additional](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.combined](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.required](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

----
<!-- END_TF_DOCS -->
