#--------------------------------------------------------------------------------------
# CORE CONFIGURATION VARIABLES
#--------------------------------------------------------------------------------------

variable "inventory_bucket_name" {
  description = "Name of the S3 inventory bucket"
  type        = string

  validation {
    condition = (
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.inventory_bucket_name))
      && length(var.inventory_bucket_name) >= 3
      && length(var.inventory_bucket_name) <= 63
    )
    error_message = "Inventory bucket name must be a valid S3 bucket name (3-63 characters, lowercase letters, numbers, periods, and hyphens only)."
  }
}

variable "inventory_database_name" {
  description = "Name of the S3 inventory Glue database"
  type        = string

  validation {
    condition = (
      can(regex("^[a-zA-Z_][a-zA-Z0-9_-]*$", var.inventory_database_name))
      && length(var.inventory_database_name) <= 255
    )
    error_message = "Database name must start with a letter or underscore, contain only alphanumeric characters, underscores and hyphens, and be at most 255 characters long."
  }
}

variable "inventory_tables_description" {
  description = "Description to set on every S3 inventory Glue table. If not provided, a default will be used."
  type        = string
  default     = null
}

variable "source_bucket_names" {
  description = "List of S3 bucket names to create inventory reports for"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for bucket in var.source_bucket_names : (
        can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", bucket))
        && length(bucket) >= 3
        && length(bucket) <= 63
      )
    ])
    error_message = "All bucket names must be valid S3 bucket names (3-63 characters, lowercase letters, numbers, periods, and hyphens only)."
  }

  validation {
    condition     = length(var.source_bucket_names) == length(distinct(var.source_bucket_names))
    error_message = "The source_bucket_names list must not contain duplicate values."
  }
}

#--------------------------------------------------------------------------------------
# RESOURCE CREATION FLAGS
#--------------------------------------------------------------------------------------
variable "enable_bucket_inventory_configs" {
  description = "Whether to create S3 inventory configurations for the specified buckets"
  type        = bool
  default     = true
}

#--------------------------------------------------------------------------------------
# BUCKET POLICY CONFIGURATION
#--------------------------------------------------------------------------------------
variable "attach_bucket_policy" {
  description = <<-EOT
    Whether module should attach the policy to the inventory bucket.
    Set to false if:
    - You want to attach the policy yourself using the s3_bucket_policy_json or s3_bucket_required_policy_json outputs
    - The bucket already has a policy and you want to merge them yourself
    - You only want to use this module to generate the policy statements
  EOT
  type        = bool
  default     = true
}

variable "additional_bucket_policy_statements" {
  description = "Additional IAM policy statements to include in the bucket policy (will be merged with module's statements)"
  type = list(object({
    Sid       = optional(string)
    Effect    = string
    Principal = any
    Action    = any
    Resource  = any
    Condition = optional(any)
  }))
  default = []
}

#--------------------------------------------------------------------------------------
# S3 INVENTORY CONFIGURATION
#--------------------------------------------------------------------------------------

variable "inventory_config_name" {
  description = "Name identifier for the S3 inventory configuration"
  type        = string
  default     = "daily"

  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.inventory_config_name))
    error_message = "Inventory configuration name can only contain alphanumeric characters, hyphens and underscores."
  }
}

variable "inventory_config_frequency" {
  description = "Frequency of the S3 inventory report generation"
  type        = string
  default     = "Daily"

  validation {
    condition     = contains(["Daily"], var.inventory_config_frequency)
    error_message = "Inventory frequency must be 'Daily'."
  }
}

variable "inventory_config_object_versions" {
  description = "Which object versions to include in the inventory report"
  type        = string
  default     = "All"

  validation {
    condition     = contains(["All", "Current"], var.inventory_config_object_versions)
    error_message = "Object versions must be either 'All' (include all versions) or 'Current' (current versions only)."
  }
}

variable "inventory_optional_fields" {
  description = "List of optional fields to include in the S3 inventory report"
  type        = list(string)
  default = [
    "Size",
    "LastModifiedDate",
    "IsMultipartUploaded",
    "ReplicationStatus",
    "EncryptionStatus",
    "BucketKeyStatus",
    "StorageClass",
    "IntelligentTieringAccessTier",
    "ETag",
    "ChecksumAlgorithm",
    "ObjectLockRetainUntilDate",
    "ObjectLockMode",
    "ObjectLockLegalHoldStatus",
    "ObjectAccessControlList",
    "ObjectOwner"
  ]

  validation {
    condition = alltrue([
      for field in var.inventory_optional_fields : contains([
        "Size",
        "LastModifiedDate",
        "StorageClass",
        "ETag",
        "IsMultipartUploaded",
        "ReplicationStatus",
        "EncryptionStatus",
        "ObjectLockRetainUntilDate",
        "ObjectLockMode",
        "ObjectLockLegalHoldStatus",
        "IntelligentTieringAccessTier",
        "BucketKeyStatus",
        "ChecksumAlgorithm",
        "ObjectAccessControlList",
        "ObjectOwner"
      ], field)
    ])
    error_message = "All inventory optional fields must be valid AWS S3 inventory fields."
  }
}


variable "inventory_config_encryption" {
  description = "Map containing encryption settings for the S3 inventory configuration."
  type        = any
  default     = {}
}

#--------------------------------------------------------------------------------------
# VIEWS
#--------------------------------------------------------------------------------------

variable "union_all_view_name" {
  description = "Name for the Athena view that unions ALL inventory partitions from all source buckets (complete historical data)"
  type        = string
  default     = null

  validation {
    condition = var.union_all_view_name == null ? true : (
      can(regex("^[a-zA-Z0-9._-]+$", var.union_all_view_name))
    )
    error_message = "Union all view name can only contain alphanumeric characters, periods, hyphens, and underscores."
  }
}

variable "union_latest_view_name" {
  description = "Name for the Athena view that unions the LATEST inventory partition from each source bucket (current state only, more efficient)"
  type        = string
  default     = null

  validation {
    condition = var.union_latest_view_name == null ? true : (
      can(regex("^[a-zA-Z0-9._-]+$", var.union_latest_view_name))
    )
    error_message = "Union latest view name can only contain alphanumeric characters, periods, hyphens, and underscores."
  }
}

#--------------------------------------------------------------------------------------
# ATHENA AND QUERYING CONFIGURATION
#--------------------------------------------------------------------------------------

variable "athena_projection_dt_range" {
  description = "Date range for Athena partition projection (format: START_DATE,END_DATE). If null then a value will be generated, see README for more information."
  type        = string
  default     = null

  validation {
    condition = var.athena_projection_dt_range == null ? true : (
      can(
        regex(
          "^(NOW([+-]\\d+(DAYS?|MONTHS?|YEARS?))?|\\d{4}-\\d{2}-\\d{2}),(NOW([+-]\\d+(DAYS?|MONTHS?|YEARS?))?|\\d{4}-\\d{2}-\\d{2})$", var.athena_projection_dt_range
        )
      )
    )
    error_message = "Date range must be in format 'START,END' where dates are either 'YYYY-MM-DD-HH-MM' or 'NOW' with optional offsets like 'NOW-3MONTHS'."
  }
}

#--------------------------------------------------------------------------------------
# IAM PERMISSIONS
#--------------------------------------------------------------------------------------

variable "database_admin_principals" {
  description = "List of principal ARNs that will be allowed to manage (create, update, delete) the Glue database and its tables. Must not contain duplicates or overlap with database_read_principals."
  type        = list(string)
  default = [
    # "arn:aws:iam::123456789012:role/some-management-role"
  ]

  validation {
    condition     = length(var.database_admin_principals) == length(distinct(var.database_admin_principals))
    error_message = "The database_admin_principals list must not contain duplicate values."
  }
}

variable "database_read_principals" {
  description = "List of principal ARNs that will be allowed to read from the Glue database (query tables, describe metadata). Must not contain duplicates or overlap with database_admin_principals."
  type        = list(string)
  default = [
    # "arn:aws:iam::123456789012:role/some-read-role"
  ]

  validation {
    condition     = length(var.database_read_principals) == length(distinct(var.database_read_principals))
    error_message = "The database_read_principals list must not contain duplicate values."
  }
}
