output "athena_projection_dt_range" {
  description = "The value used for projection.dt.range on the Glue table"
  value       = local.athena_projection_dt_range
}

output "union_all_view_name" {
  description = "Name of the created union all view (all partitions from all buckets), if enabled"
  value       = var.union_all_view_name
}

output "union_latest_view_name" {
  description = "Name of the created union latest view (latest partition from each bucket), if enabled"
  value       = var.union_latest_view_name
}

output "bucket_policy" {
  description = "Complete bucket policy JSON including required statements and any additional statements. Use this to attach the policy yourself when attach_bucket_policy = false"
  value       = local.policy_document
}

output "required_bucket_policy" {
  description = "Required bucket policy JSON (S3 inventory write permissions only). Use with source_policy_documents to merge with your custom policy"
  value       = local.required_policy_document
}
