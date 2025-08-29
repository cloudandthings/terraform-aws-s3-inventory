
# ---------------------------------------------------------------------
# ALL Lake Formation Permissions for S3 Inventory Database and Tables
# ---------------------------------------------------------------------
resource "aws_lakeformation_permissions" "inventory_database_admin" {
  count     = length(var.database_admin_principals)
  principal = var.database_admin_principals[count.index]

  # List of Database Permissions
  # ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]

  permissions = [
    "ALL",
    "ALTER",
    "CREATE_TABLE",
    "DESCRIBE",
    "DROP"
  ]

  permissions_with_grant_option = [
    "ALL",
    "ALTER",
    "CREATE_TABLE",
    "DESCRIBE",
    "DROP"
  ]

  database {
    catalog_id = local.account_id
    name       = local.inventory_database_name
  }
}

resource "aws_lakeformation_permissions" "inventory_tables_admin" {
  count     = length(var.database_admin_principals)
  principal = var.database_admin_principals[count.index]

  # List of Table Permissions
  # ["ALL", "ALTER", "DELETE", "DESCRIBE", "DROP", "INSERT", "SELECT"]

  permissions = [
    "ALL",
    "ALTER",
    "DELETE",
    "DESCRIBE",
    "DROP",
    "INSERT",
    "SELECT"
  ]

  permissions_with_grant_option = [
    "ALL",
    "ALTER",
    "DELETE",
    "DESCRIBE",
    "DROP",
    "INSERT",
    "SELECT"
  ]

  table {
    catalog_id    = local.account_id
    database_name = local.inventory_database_name
    wildcard      = true
  }
}

# ---------------------------------------------------------------------
# READ Lake Formation Permissions for S3 Inventory Database and Tables
# ---------------------------------------------------------------------
resource "aws_lakeformation_permissions" "inventory_database_read" {
  count     = length(var.database_read_principals)
  principal = var.database_read_principals[count.index]

  # List of Database Permissions
  # ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]
  permissions = ["DESCRIBE"]

  database {
    catalog_id = local.account_id
    name       = local.inventory_database_name
  }
}

resource "aws_lakeformation_permissions" "inventory_tables_read" {
  count     = length(var.database_read_principals)
  principal = var.database_read_principals[count.index]

  # List of Table Permissions
  # ["ALL", "ALTER", "DELETE", "DESCRIBE", "DROP", "INSERT", "SELECT"]
  permissions = ["DESCRIBE", "SELECT"]

  table {
    catalog_id    = local.account_id
    database_name = local.inventory_database_name
    wildcard      = true
  }
}
