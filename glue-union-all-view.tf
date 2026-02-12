#--------------------------------------------------------------------------------------
# UNION ALL VIEW - All inventory partitions from all buckets (complete historical data)
#--------------------------------------------------------------------------------------

locals {
  union_all_sql = join(
    "\nUNION ALL\n",
    [
      for bucket in sort(local.source_bucket_names) :
      format(
        "SELECT * FROM \"%s\".\"%s\"",
        var.inventory_database_name,
        bucket
      )
    ]
  )
}

locals {
  union_all_presto_view = jsonencode({
    originalSql = local.union_all_sql,
    catalog     = "awsdatacatalog",
    schema      = var.inventory_database_name,
    columns = [
      for column in local.inventory_columns_incl_partition :
      { name = column.name, type = column.presto_type }
    ],
  })
}

moved {
  from = aws_glue_catalog_table.view
  to   = aws_glue_catalog_table.union_all_view
}

resource "aws_glue_catalog_table" "union_all_view" {
  count = var.union_all_view_name == null ? 0 : 1

  database_name = var.inventory_database_name
  name          = var.union_all_view_name
  description   = coalesce(var.inventory_tables_description, local.description)

  table_type         = "VIRTUAL_VIEW"
  view_original_text = "/* Presto View: ${base64encode(local.union_all_presto_view)} */"

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
