# Zone settings (SSL/TLS, HTTPS, protocols, ...).
# One cloudflare_zone_setting per entry in var.zone_settings, keyed by Cloudflare's setting ID.
# Zone settings cannot be deleted: removing an entry only stops Terraform from managing it,
# and the zone keeps its last value. To revert a setting, set it back explicitly.

resource "cloudflare_zone_setting" "settings" {
  for_each = var.zone_settings

  zone_id    = var.zone_id
  setting_id = each.key
  value      = each.value
}
