output "module_example" {
  description = "module.inventory"
  value       = module.inventory
}

output "custom_bucket_policy" {
  description = "The custom bucket policy combining default and additional statements"
  value       = data.aws_iam_policy_document.custom_inventory_bucket_policy.json
}
