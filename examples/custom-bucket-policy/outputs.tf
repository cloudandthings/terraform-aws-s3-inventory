output "module_inventory" {
  description = "Complete module outputs including bucket and database information"
  value       = module.inventory
}

output "inventory_reader_role_arn" {
  description = "ARN of the example IAM role that can read inventory data"
  value       = aws_iam_role.inventory_reader.arn
}
