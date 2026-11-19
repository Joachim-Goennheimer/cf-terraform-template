# R2 buckets (S3-compatible object storage).

resource "cloudflare_r2_bucket" "buckets" {
  for_each = var.r2_buckets

  account_id    = var.account_id
  name          = "${var.app_name}-${each.key}"
  jurisdiction  = each.value.jurisdiction
  location      = each.value.location
  storage_class = each.value.storage_class

  # Deletion protection: any plan that would delete or replace a bucket fails. To delete one
  # on purpose, temporarily remove this line in a dedicated PR.
  lifecycle {
    prevent_destroy = true
  }
}
