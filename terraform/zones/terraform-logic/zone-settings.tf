# Zone settings (SSL/TLS, HTTPS, protocols, ...).
# One cloudflare_zone_setting per entry in var.zone_settings, keyed by Cloudflare's setting ID.

resource "cloudflare_zone_setting" "settings" {
  for_each = var.zone_settings

  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}
