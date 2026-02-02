#--------------------------------------------------------------------------------------
# UNION LATEST VIEW - Latest inventory partition from each bucket (current state only)
#--------------------------------------------------------------------------------------

locals {
  # SQL to select only the latest partition (dt) from each bucket
  # This is much more efficient than scanning all historical partitions
  union_latest_sql = join(
    "\nUNION ALL\n",
    [
      for bucket in var.source_bucket_names :
      format(
        "SELECT * FROM \"%s\".\"%s\" WHERE dt >= DATE_FORMAT(date_add('day', -1, CURRENT_DATE), '%Y-%m-%d') AND dt < DATE_FORMAT(CURRENT_DATE, '%Y-%m-%d')",
        var.inventory_database_name,
        bucket
      )
    ]
  )
}

locals {
  union_latest_presto_view = jsonencode({
    originalSql = local.union_latest_sql,
    catalog     = "awsdatacatalog",
    schema      = var.inventory_database_name,
    columns = [
      for column in local.inventory_columns_incl_partition :
      { name = column.name, type = column.presto_type }
    ],
  })
}

resource "aws_glue_catalog_table" "union_latest_view" {
  count = var.union_latest_view_name == null ? 0 : 1

  database_name = var.inventory_database_name
  name          = var.union_latest_view_name
  description   = "View showing only the most recent inventory snapshot for each source bucket. ${coalesce(var.inventory_tables_description, local.description)}"

  table_type         = "VIRTUAL_VIEW"
  view_original_text = "/* Presto View: ${base64encode(local.union_latest_presto_view)} */"

  storage_descriptor {
    ser_de_info {
      name                  = "-"
      serialization_library = "-"
    }
    dynamic "columns" {
      for_each = local.inventory_columns_incl_partition
      content {
        name = columns.value.name
        type = columns.value.hive_type
      }
    }
  }
  parameters = {
    presto_view = "true"
  }
}
