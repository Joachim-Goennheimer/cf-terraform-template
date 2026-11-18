# DNS records for the zone.
# Records are keyed by the map key from tfvars (not by list position), so adding or removing
# one record never causes other records to be replaced.

resource "cloudflare_dns_record" "records" {
  for_each = var.dns_records

  zone_id  = var.zone_id
  name     = each.value.name == "@" ? var.zone_name : "${each.value.name}.${var.zone_name}"
  type     = each.value.type
  content  = each.value.content
  ttl      = each.value.ttl
  proxied  = each.value.proxied
  priority = each.value.priority
  comment  = each.value.comment
}
