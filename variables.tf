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
}

#--------------------------------------------------------------------------------------
# RESOURCE CREATION FLAGS
#--------------------------------------------------------------------------------------

variable "create_inventory_bucket" {
  description = "Whether to create the S3 inventory bucket"
  type        = bool
  default     = true
}

variable "create_inventory_database" {
  description = "Whether to create the Glue database for S3 inventory"
  type        = bool
  default     = true
}

variable "enable_bucket_inventory_configs" {
  description = "Whether to create S3 inventory configurations for the specified buckets"
  type        = bool
  default     = true
}

variable "attach_default_inventory_bucket_policy" {
  description = "Whether to attach a default bucket policy to the S3 inventory bucket"
  type        = bool
  default     = true
}

variable "apply_default_inventory_lifecyle_rules" {
  description = "Whether to attach default lifecycle rules to the S3 inventory bucket"
  type        = bool
  default     = true
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

variable "union_view_name" {
  description = "Name for the Athena view over S3 inventory data from all the source buckets"
  type        = string
  default     = null

  validation {
    condition = var.union_view_name == null ? true : (
      can(regex("^[a-zA-Z0-9._-]+$", var.union_view_name))
    )
    error_message = "Union view name can only contain alphanumeric characters, periods, hyphens, and underscores."
  }
}

#--------------------------------------------------------------------------------------
# S3 BUCKET LIFECYCLE AND RETENTION
#--------------------------------------------------------------------------------------

variable "inventory_bucket_lifecycle_rules" {
  description = "List of lifecycle rules to apply to the S3 inventory bucket"
  type        = any
  default     = []
}

variable "inventory_bucket_object_lock_retention_days" {
  description = "Number of days to retain objects with Object Lock (null to disable Object Lock)"
  type        = number
  default     = null

  validation {
    condition = var.inventory_bucket_object_lock_retention_days == null ? true : (
      var.inventory_bucket_object_lock_retention_days >= 1
      && var.inventory_bucket_object_lock_retention_days <= 36500
    )
    error_message = "Object Lock retention days must be between 1 and 36500 (100 years) or null to disable."
  }
}

variable "inventory_bucket_object_lock_mode" {
  description = "Object Lock mode for the S3 inventory bucket (GOVERNANCE or COMPLIANCE)"
  type        = string
  default     = "GOVERNANCE"


  validation {
    condition     = contains(["GOVERNANCE", "COMPLIANCE"], var.inventory_bucket_object_lock_mode)
    error_message = "Object Lock mode must be either 'GOVERNANCE' or 'COMPLIANCE'."
  }
}

#--------------------------------------------------------------------------------------
# S3 BUCKET SECURITY AND ENCRYPTION
#--------------------------------------------------------------------------------------

variable "inventory_bucket_encryption_config" {
  description = "Map containing server-side encryption configuration for the S3 inventory bucket."
  type        = any
  default     = {}
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
  description = "List of principal ARNs that will be allowed to manage (create, update, delete) the Glue database and its tables"
  type        = list(string)
  default = [
    # "arn:aws:iam::123456789012:role/some-management-role"
  ]
}

variable "database_read_principals" {
  description = "List of principal ARNs that will be allowed to read from the Glue database (query tables, describe metadata)"
  type        = list(string)
  default = [
    # "arn:aws:iam::123456789012:role/some-read-role"
  ]
}
