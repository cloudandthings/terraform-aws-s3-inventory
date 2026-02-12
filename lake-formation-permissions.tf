# ---------------------------------------------------------------------
# ALL Lake Formation Permissions for S3 Inventory Database and Tables
# ---------------------------------------------------------------------
resource "aws_lakeformation_permissions" "inventory_database_admin" {
  for_each  = local.database_admin_principals
  principal = each.value

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
    name       = var.inventory_database_name
  }

  lifecycle {
    precondition {
      condition = length(setintersection(
        var.database_admin_principals,
        var.database_read_principals
      )) == 0
      error_message = "Database admin and read principals must have no overlapping values. Ensure no principal is in both lists."
    }
  }
}

resource "aws_lakeformation_permissions" "inventory_tables_admin" {
  for_each  = local.database_admin_principals
  principal = each.value

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
    database_name = var.inventory_database_name
    wildcard      = true
  }

  lifecycle {
    precondition {
      condition = length(setintersection(
        var.database_admin_principals,
        var.database_read_principals
      )) == 0
      error_message = "Database admin and read principals must have no overlapping values. Ensure no principal is in both lists."
    }
  }
}

# ---------------------------------------------------------------------
# READ Lake Formation Permissions for S3 Inventory Database and Tables
# ---------------------------------------------------------------------
resource "aws_lakeformation_permissions" "inventory_database_read" {
  for_each  = local.database_read_principals
  principal = each.value

  # List of Database Permissions
  # ["ALL", "ALTER", "CREATE_TABLE", "DESCRIBE", "DROP"]
  permissions = ["DESCRIBE"]

  database {
    catalog_id = local.account_id
    name       = var.inventory_database_name
  }

  lifecycle {
    precondition {
      condition = length(setintersection(
        var.database_admin_principals,
        var.database_read_principals
      )) == 0
      error_message = "Database admin and read principals must have no overlapping values. Ensure no principal is in both lists."
    }
  }
}

resource "aws_lakeformation_permissions" "inventory_tables_read" {
  for_each  = local.database_read_principals
  principal = each.value

  # List of Table Permissions
  # ["ALL", "ALTER", "DELETE", "DESCRIBE", "DROP", "INSERT", "SELECT"]
  permissions = ["DESCRIBE", "SELECT"]

  table {
    catalog_id    = local.account_id
    database_name = var.inventory_database_name
    wildcard      = true
  }

  lifecycle {
    precondition {
      condition = length(setintersection(
        var.database_admin_principals,
        var.database_read_principals
      )) == 0
      error_message = "Database admin and read principals must have no overlapping values. Ensure no principal is in both lists."
    }
  }
}
