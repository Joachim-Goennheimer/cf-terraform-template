# D1 databases (serverless SQLite). Schema changes are NOT managed here: they are applied as
# migrations by the app's deploy pipeline (wrangler d1 migrations apply).

resource "cloudflare_d1_database" "databases" {
  for_each = var.d1_databases

  account_id            = var.account_id
  name                  = "${var.app_name}-${each.key}"
  jurisdiction          = each.value.jurisdiction
  primary_location_hint = each.value.primary_location_hint

  # Deletion protection: any plan that would delete or replace a database fails. To delete one
  # on purpose, temporarily remove this line in a dedicated PR.
  lifecycle {
    prevent_destroy = true
  }
}
