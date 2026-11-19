# Workers KV namespaces (globally replicated key-value store).

resource "cloudflare_workers_kv_namespace" "namespaces" {
  for_each = var.kv_namespaces

  account_id   = var.account_id
  title        = "${var.app_name}-${each.key}"
  jurisdiction = each.value.jurisdiction
}
