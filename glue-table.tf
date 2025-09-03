resource "aws_glue_catalog_database" "s3_inventory" {
  count = var.create_inventory_database ? 1 : 0
  name  = var.inventory_database_name
}

locals {
  # See README for more information.
  # This calculation causes Terraform to drift annually.
  last_year                          = tonumber(formatdate("YYYY", timestamp())) - 1
  default_athena_projection_dt_range = "${local.last_year}-01-01-00-00,NOW"

  athena_projection_dt_range = (
    var.athena_projection_dt_range != null
    ? var.athena_projection_dt_range
    : local.default_athena_projection_dt_range
  )
}

resource "aws_glue_catalog_table" "s3_inventory" {
  count         = length(var.source_bucket_names)
  name          = var.source_bucket_names[count.index]
  database_name = local.inventory_database_name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    # Lexicographical order to prevent TF plan drift
    "projection.dt.format"        = "yyyy-MM-dd-HH-mm"
    "projection.dt.interval"      = "1"
    "projection.dt.interval.unit" = "HOURS"
    "projection.dt.range"         = local.athena_projection_dt_range
    "projection.dt.type"          = "date"
    "projection.enabled"          = "true"
  }

  partition_keys {
    name = "dt"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${local.inventory_bucket_name}/${var.source_bucket_names[count.index]}/${var.inventory_config_name}/hive/"
    input_format  = "org.apache.hadoop.hive.ql.io.SymlinkTextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "parquet"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
      parameters = {
        "serialization.format" = "1"
      }
    }

    dynamic "columns" {
      for_each = local.inventory_columns_excl_partition
      content {
        name = columns.value.name
        type = columns.value.hive_type
      }
    }
  }

  lifecycle {
    ignore_changes = [
      # Ignore ordering changes in parameters map
      parameters,
    ]
  }
}
