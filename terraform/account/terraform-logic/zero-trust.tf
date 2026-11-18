# Zero Trust organization and device (WARP client) profiles.

resource "cloudflare_zero_trust_organization" "main" {
  count = var.zero_trust_organization != null ? 1 : 0

  account_id       = var.account_id
  name             = var.zero_trust_organization.name
  auth_domain      = var.zero_trust_organization.auth_domain
  session_duration = var.zero_trust_organization.session_duration
  is_ui_read_only  = var.zero_trust_organization.is_ui_read_only
}

# Default device profile: applies to every device that matches no custom profile.
resource "cloudflare_zero_trust_device_default_profile" "default" {
  count = var.zero_trust_device_default_profile != null ? 1 : 0

  account_id            = var.account_id
  allow_mode_switch     = var.zero_trust_device_default_profile.allow_mode_switch
  allow_updates         = var.zero_trust_device_default_profile.allow_updates
  allowed_to_leave      = var.zero_trust_device_default_profile.allowed_to_leave
  auto_connect          = var.zero_trust_device_default_profile.auto_connect
  captive_portal        = var.zero_trust_device_default_profile.captive_portal
  disable_auto_fallback = var.zero_trust_device_default_profile.disable_auto_fallback
  exclude_office_ips    = var.zero_trust_device_default_profile.exclude_office_ips
  service_mode_v2       = var.zero_trust_device_default_profile.service_mode_v2
  support_url           = var.zero_trust_device_default_profile.support_url
  switch_locked         = var.zero_trust_device_default_profile.switch_locked
  tunnel_protocol       = var.zero_trust_device_default_profile.tunnel_protocol
}

# Custom device profiles: applied to devices whose user/device matches `match`,
# evaluated in ascending `precedence` order.
resource "cloudflare_zero_trust_device_custom_profile" "custom" {
  for_each = { for profile in var.zero_trust_device_custom_profiles : profile.name => profile }

  account_id            = var.account_id
  name                  = each.value.name
  description           = each.value.description
  enabled               = each.value.enabled
  match                 = each.value.match
  precedence            = each.value.precedence
  allow_mode_switch     = each.value.allow_mode_switch
  allow_updates         = each.value.allow_updates
  allowed_to_leave      = each.value.allowed_to_leave
  auto_connect          = each.value.auto_connect
  captive_portal        = each.value.captive_portal
  disable_auto_fallback = each.value.disable_auto_fallback
  exclude_office_ips    = each.value.exclude_office_ips
  service_mode_v2       = each.value.service_mode_v2
  support_url           = each.value.support_url
  switch_locked         = each.value.switch_locked
  tunnel_protocol       = each.value.tunnel_protocol
}
