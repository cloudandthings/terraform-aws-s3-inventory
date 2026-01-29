output "athena_projection_dt_range" {
  description = "The value used for projection.dt.range on the Glue table"
  value       = local.athena_projection_dt_range
}

output "default_inventory_bucket_policy_json" {
  description = "The default bucket policy document in JSON format (without user-provided custom statements)"
  value       = data.aws_iam_policy_document.default_inventory_bucket_policy.json
}

output "inventory_bucket_policy_json" {
  description = "The complete bucket policy document in JSON format (including both default and custom statements if provided)"
  value       = data.aws_iam_policy_document.inventory_bucket_policy.json
}
