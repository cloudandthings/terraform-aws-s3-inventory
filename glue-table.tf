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

  description = jsonencode(data.aws_default_tags.current.tags)
}

resource "aws_glue_catalog_table" "s3_inventory" {
  for_each = local.source_bucket_names

  database_name = var.inventory_database_name
  name          = each.value
  description   = coalesce(var.inventory_tables_description, local.description)

  table_type = "EXTERNAL_TABLE"

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
    location      = "s3://${var.inventory_bucket_name}/${each.value}/${var.inventory_config_name}/hive/"
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
