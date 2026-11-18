# Outputs for account-level resources.

output "account_id" {
  description = "Cloudflare account ID"
  value       = data.cloudflare_account.main.id
}

output "account_name" {
  description = "Cloudflare account name"
  value       = data.cloudflare_account.main.name
}
