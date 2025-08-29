# Terraform AWS S3 Inventory Module

A comprehensive Terraform module for managing AWS S3 inventory configurations, including automated inventory reports, Glue catalog integration, and Athena querying capabilities.

## Features

- **S3 Inventory Destination Bucket**: Creates a dedicated S3 bucket for storing all inventory reports
- **S3 Inventory Management**: Creates and configures S3 inventory reports for multiple source buckets
- **Glue Catalog Integration**: Sets up Glue database and tables for querying inventory data
- **Unified View**: Optional creation of a union view across all inventory tables for cross-bucket analysis
- **Security & Compliance**: Configurable encryption, object locking, and IAM and LakeFormation permissions
- **Lifecycle Management**: Automated lifecycle rules for inventory report retention

Many features are optional and can be enabled/disabled as required.

----

## Quick Start

```hcl
module "s3_inventory" {
  source  = "cloudandthings/terraform-aws-s3-inventory/aws"
  version = "~> 1.0"

  # Required variables
  inventory_bucket_name   = "my-company-s3-inventory"
  inventory_database_name = "s3_inventory_db"

  # Source buckets to inventory
  source_bucket_names = [
    "my-app-data-bucket",
    "my-logs-bucket",
    "my-backup-bucket"
  ]

  # Optional: Create a union view for cross-bucket queries
  union_view_name = "all_inventories_view"

  # Optional: Add LakeFormation permissions
  # database_admin_principals = [...]
  # database_read_principals = [...]

}
```


----
## Usage

See `examples` dropdown on Terraform Cloud, or [browse here](/examples/).

----

## Querying Your Inventory Data

Once deployed, you can query your S3 inventory data using Amazon Athena.

Query a single bucket's inventory:

```sql
SELECT bucket, key, size, last_modified_date, storage_class
FROM s3_inventory_db.my_app_data_bucket
WHERE dt = '2024-08-29-00-00'
ORDER BY size DESC
LIMIT 100;
```

Query across all buckets (using the union view):

```sql
SELECT bucket, COUNT(*) as object_count, SUM(size) as total_size, AVG(size) as avg_size FROM s3_inventory_db.all_inventories_view
WHERE dt >= '2024-08-01-00-00'
GROUP BY bucket
ORDER BY total_size DESC;
```

----

## Important Considerations

### Athena Partition Date Projection

As of 2025, Amazon Athena does not properly support dynamic range projection with the S3 inventory partitioning scheme. When using a dynamic range like `"NOW-3MONTHS,NOW"`, the Glue tables will return zero rows.

To work around this limitation, this Terraform module defaults to using the beginning of the previous year as the start date. The year is calculated based on when the Terraform plan runs. For example, if today is 2025-08-25, the date range will be set to `"2024-01-01-00-00,NOW"`.

**Important:** This approach causes Terraform state drift annually when the year changes.

### Workaround

To avoid state drift, provide a fixed start date such as:

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

See [`CONTRIBUTING.md`](./.github/CONTRIBUTING.md) for further information.


----
## License

This project is currently unlicensed. Please contact the maintaining team to add a license.

----

*This module was created from [terraform-aws-template](https://github.com/cloudandthings/terraform-aws-template)*


<!-- BEGIN_TF_DOCS -->
----
## Documentation

----
### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apply_default_inventory_lifecyle_rules"></a> [apply\_default\_inventory\_lifecyle\_rules](#input\_apply\_default\_inventory\_lifecyle\_rules) | Whether to attach default lifecycle rules to the S3 inventory bucket | `bool` | `true` | no |
| <a name="input_athena_projection_dt_range"></a> [athena\_projection\_dt\_range](#input\_athena\_projection\_dt\_range) | Date range for Athena partition projection (format: START\_DATE,END\_DATE). If null then a value will be generated, see README for more information. | `string` | `null` | no |
| <a name="input_attach_default_inventory_bucket_policy"></a> [attach\_default\_inventory\_bucket\_policy](#input\_attach\_default\_inventory\_bucket\_policy) | Whether to attach a default bucket policy to the S3 inventory bucket | `bool` | `true` | no |
| <a name="input_create_inventory_bucket"></a> [create\_inventory\_bucket](#input\_create\_inventory\_bucket) | Whether to create the S3 inventory bucket | `bool` | `true` | no |
| <a name="input_create_inventory_database"></a> [create\_inventory\_database](#input\_create\_inventory\_database) | Whether to create the Glue database for S3 inventory | `bool` | `true` | no |
| <a name="input_database_admin_principals"></a> [database\_admin\_principals](#input\_database\_admin\_principals) | List of principal ARNs that will be allowed to manage (create, update, delete) the Glue database and its tables | `list(string)` | `[]` | no |
| <a name="input_database_read_principals"></a> [database\_read\_principals](#input\_database\_read\_principals) | List of principal ARNs that will be allowed to read from the Glue database (query tables, describe metadata) | `list(string)` | `[]` | no |
| <a name="input_enable_bucket_inventory_configs"></a> [enable\_bucket\_inventory\_configs](#input\_enable\_bucket\_inventory\_configs) | Whether to create S3 inventory configurations for the specified buckets | `bool` | `true` | no |
| <a name="input_inventory_bucket_encryption_config"></a> [inventory\_bucket\_encryption\_config](#input\_inventory\_bucket\_encryption\_config) | Map containing server-side encryption configuration for the S3 inventory bucket. | `any` | `{}` | no |
| <a name="input_inventory_bucket_lifecycle_rules"></a> [inventory\_bucket\_lifecycle\_rules](#input\_inventory\_bucket\_lifecycle\_rules) | List of lifecycle rules to apply to the S3 inventory bucket | `any` | `[]` | no |
| <a name="input_inventory_bucket_name"></a> [inventory\_bucket\_name](#input\_inventory\_bucket\_name) | Name of the S3 inventory bucket | `string` | n/a | yes |
| <a name="input_inventory_bucket_object_lock_mode"></a> [inventory\_bucket\_object\_lock\_mode](#input\_inventory\_bucket\_object\_lock\_mode) | Object Lock mode for the S3 inventory bucket (GOVERNANCE or COMPLIANCE) | `string` | `"GOVERNANCE"` | no |
| <a name="input_inventory_bucket_object_lock_retention_days"></a> [inventory\_bucket\_object\_lock\_retention\_days](#input\_inventory\_bucket\_object\_lock\_retention\_days) | Number of days to retain objects with Object Lock (null to disable Object Lock) | `number` | `null` | no |
| <a name="input_inventory_config_encryption"></a> [inventory\_config\_encryption](#input\_inventory\_config\_encryption) | Map containing encryption settings for the S3 inventory configuration. | `any` | `{}` | no |
| <a name="input_inventory_config_frequency"></a> [inventory\_config\_frequency](#input\_inventory\_config\_frequency) | Frequency of the S3 inventory report generation | `string` | `"Daily"` | no |
| <a name="input_inventory_config_name"></a> [inventory\_config\_name](#input\_inventory\_config\_name) | Name identifier for the S3 inventory configuration | `string` | `"daily"` | no |
| <a name="input_inventory_config_object_versions"></a> [inventory\_config\_object\_versions](#input\_inventory\_config\_object\_versions) | Which object versions to include in the inventory report | `string` | `"All"` | no |
| <a name="input_inventory_database_name"></a> [inventory\_database\_name](#input\_inventory\_database\_name) | Name of the S3 inventory Glue database | `string` | n/a | yes |
| <a name="input_inventory_optional_fields"></a> [inventory\_optional\_fields](#input\_inventory\_optional\_fields) | List of optional fields to include in the S3 inventory report | `list(string)` | <pre>[<br/>  "Size",<br/>  "LastModifiedDate",<br/>  "IsMultipartUploaded",<br/>  "ReplicationStatus",<br/>  "EncryptionStatus",<br/>  "BucketKeyStatus",<br/>  "StorageClass",<br/>  "IntelligentTieringAccessTier",<br/>  "ETag",<br/>  "ChecksumAlgorithm",<br/>  "ObjectLockRetainUntilDate",<br/>  "ObjectLockMode",<br/>  "ObjectLockLegalHoldStatus",<br/>  "ObjectAccessControlList",<br/>  "ObjectOwner"<br/>]</pre> | no |
| <a name="input_source_bucket_names"></a> [source\_bucket\_names](#input\_source\_bucket\_names) | List of S3 bucket names to create inventory reports for | `list(string)` | `[]` | no |
| <a name="input_union_view_name"></a> [union\_view\_name](#input\_union\_view\_name) | Name for the Athena view over S3 inventory data from all the source buckets | `string` | `null` | no |

----
### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_inventory_bucket"></a> [inventory\_bucket](#module\_inventory\_bucket) | terraform-aws-modules/s3-bucket/aws | 4.6.0 |

----
### Outputs

| Name | Description |
|------|-------------|
| <a name="output_athena_projection_dt_range"></a> [athena\_projection\_dt\_range](#output\_athena\_projection\_dt\_range) | The value used for projection.dt.range on the Glue table |

----
### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5, < 7 |

----
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5, < 7 |

----
### Resources

| Name | Type |
|------|------|
| [aws_glue_catalog_database.s3_inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_database) | resource |
| [aws_glue_catalog_table.s3_inventory](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_glue_catalog_table.view](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/glue_catalog_table) | resource |
| [aws_lakeformation_permissions.inventory_database_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_lakeformation_permissions.inventory_database_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_lakeformation_permissions.inventory_tables_admin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_lakeformation_permissions.inventory_tables_read](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lakeformation_permissions) | resource |
| [aws_s3_bucket_inventory.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_inventory) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.inventory_bucket_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

----
<!-- END_TF_DOCS -->
