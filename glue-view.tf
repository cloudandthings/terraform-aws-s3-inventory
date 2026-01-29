locals {
  sql = join(
    "\nUNION ALL\n",
    [
      for bucket in var.source_bucket_names :
      format(
        "SELECT * FROM \"%s\".\"%s\"",
        var.inventory_database_name,
        bucket
      )
    ]
  )
}

locals {
  presto_view = jsonencode({
    originalSql = local.sql,
    catalog     = "awsdatacatalog",
    schema      = var.inventory_database_name,
    columns = [
      for column in local.inventory_columns_incl_partition :
      { name = column.name, type = column.presto_type }
    ],
  })
}

resource "aws_glue_catalog_table" "view" {
  count = var.union_view_name == null ? 0 : 1

  database_name = var.inventory_database_name
  name          = var.union_view_name
  description   = coalesce(var.inventory_tables_description, local.description)

  table_type         = "VIRTUAL_VIEW"
  view_original_text = "/* Presto View: ${base64encode(local.presto_view)} */"

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
