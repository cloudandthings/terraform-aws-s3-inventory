locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region

  # Ensure Terraform can plan dependencies correctly
  inventory_bucket_name = (
    var.create_inventory_bucket
    ? module.inventory_bucket[0].s3_bucket_id
    : var.inventory_bucket_name
  )
  inventory_bucket_arn = (
    var.create_inventory_bucket
    ? module.inventory_bucket[0].s3_bucket_arn
    : "arn:aws:s3:::${var.inventory_bucket_name}"
  )

  inventory_database_name = (
    var.create_inventory_database
    ? aws_glue_catalog_database.s3_inventory[0].name
    : var.inventory_database_name
  )

  inventory_default_lifecycle_rules = [
    {
      id                                     = "delete_incomplete_multipart_uploads_and_expired_markers"
      enabled                                = true
      abort_incomplete_multipart_upload_days = 7
      expiration = {
        # days = 0
        expired_object_delete_marker = true
      }
    },
    {
      id      = "transition_to_intelligent_tiering"
      enabled = true
      transition = {
        days          = 0 # No retrieval fees
        storage_class = "INTELLIGENT_TIERING"
      }
      noncurrent_version_transition = {
        days          = 0 # No retrieval fees
        storage_class = "INTELLIGENT_TIERING"
      }
    },
    {
      id      = "delete_non_current_versions_after_150_days"
      enabled = true
      filter = {
        object_size_greater_than = 0
      }
      noncurrent_version_expiration = {
        days = 150
      }
    }
  ]

  inventory_configuration = {
    included_object_versions = var.inventory_config_object_versions
    destination = {
      account_id = local.account_id
      bucket_arn = local.inventory_bucket_name
      format     = "Parquet"
      encryption = var.inventory_config_encryption
    }
    frequency       = var.inventory_config_frequency # "Daily"
    optional_fields = var.inventory_optional_fields
  }

  inventory_fields_to_columns_mapping = {
    # Required fields -> columns
    "bucket" = {
      name        = "bucket"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "key" = {
      name        = "key"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "version_id" = {
      name        = "version_id"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "is_latest" = {
      name        = "is_latest"
      hive_type   = "boolean"
      presto_type = "boolean"
    }
    "is_delete_marker" = {
      name        = "is_delete_marker"
      hive_type   = "boolean"
      presto_type = "boolean"
    }
    # Optional fields -> columns
    "Size" = {
      name        = "size"
      hive_type   = "bigint"
      presto_type = "bigint"
    }
    "LastModifiedDate" = {
      name        = "last_modified_date"
      hive_type   = "timestamp"
      presto_type = "timestamp"
    }
    "IsMultipartUploaded" = {
      name        = "is_multipart_uploaded"
      hive_type   = "boolean"
      presto_type = "boolean"
    }
    "ReplicationStatus" = {
      name        = "replication_status"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "EncryptionStatus" = {
      name        = "encryption_status"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "BucketKeyStatus" = {
      name        = "bucket_key_status"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "StorageClass" = {
      name        = "storage_class"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "IntelligentTieringAccessTier" = {
      name        = "intelligent_tiering_access_tier"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "ETag" = {
      name        = "e_tag"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "ChecksumAlgorithm" = {
      name        = "checksum_algorithm"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "ObjectLockRetainUntilDate" = {
      name        = "object_lock_retain_until_date"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "ObjectLockMode" = {
      name        = "object_lock_mode"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "ObjectLockLegalHoldStatus" = {
      name        = "object_lock_legal_hold_status"
      hive_type   = "string"
      presto_type = "varchar"
    }
    "ObjectAccessControlList" = {
      name        = "object_access_control_list"
      hive_type   = "string"
      presto_type = "varchar"
    },
    "ObjectOwner" = {
      name        = "object_owner"
      hive_type   = "string"
      presto_type = "varchar"
    }
    # Partition fields -> Columns
    "dt" = {
      name        = "dt"
      hive_type   = "string"
      presto_type = "varchar"
    }
  }

  inventory_required_fields = [
    "bucket", "key", "version_id", "is_latest", "is_delete_marker"
  ]

  # The order of the non-partition fields does not need to match the order in
  # the Parquet files, however we prefer to stitch them together in the order below.
  inventory_columns_excl_partition = concat(
    [
      for field in local.inventory_required_fields :
      local.inventory_fields_to_columns_mapping[field]
    ],
    [
      for field in var.inventory_optional_fields :
      local.inventory_fields_to_columns_mapping[field]
    ],

  )

  # The partition field should be at the end.
  inventory_columns_incl_partition = concat(
    local.inventory_columns_excl_partition,
    [
      local.inventory_fields_to_columns_mapping["dt"]
    ],
  )
}
