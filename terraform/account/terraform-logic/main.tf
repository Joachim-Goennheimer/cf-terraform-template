# Root module for account-level resources.
# Resources are split into one file per Cloudflare product (e.g. zero-trust.tf, gateway-*.tf).

# Looks up the account. This also verifies early that the API token can access it.
data "cloudflare_account" "main" {
  account_id = var.account_id
}
