resource "null_resource" "delete_me" {
  # This null resource should be deleted.

  # It exists simply to use the below variables
  # so that Terraform linting passes.
  triggers = merge(
    {
      "naming" = var.naming_prefix
    },
    var.tags
  )
}
