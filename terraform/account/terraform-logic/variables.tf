# Account-level variables, populated from ../config/account.tfvars.

variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

# ---------------------------------------------------------------------------
# Zero Trust
# ---------------------------------------------------------------------------

# Convention: setting attributes have NO defaults. Every value must be set explicitly in tfvars,
# so each setting is a deliberate decision. Only whole features default to null / [],
# which means "not managed by Terraform".

variable "zero_trust_organization" {
  description = "Zero Trust organization settings (null = not managed)"
  type = object({
    name             = string
    auth_domain      = string # <team-name>.cloudflareaccess.com
    session_duration = string # e.g. "24h"
    is_ui_read_only  = bool   # true = dashboard is read-only, so changes must go through Terraform/API
  })
  default = null
}

variable "zero_trust_device_default_profile" {
  description = "Default device profile, applied to all devices that match no custom profile (null = not managed)"
  type = object({
    allow_mode_switch     = bool
    allow_updates         = bool
    allowed_to_leave      = bool
    auto_connect          = number
    captive_portal        = number
    disable_auto_fallback = bool
    exclude_office_ips    = bool
    service_mode_v2       = object({ mode = string })
    support_url           = string
    switch_locked         = bool
    tunnel_protocol       = string # "masque" or "wireguard"
  })
  default = null
}

variable "zero_trust_device_custom_profiles" {
  description = "Custom device profiles, applied to devices matching a wirefilter expression"
  type = list(object({
    name                  = string
    description           = string
    enabled               = bool
    match                 = string # e.g. any(identity.groups.name[*] in {"developers"})
    precedence            = number # lower = evaluated first
    allow_mode_switch     = bool
    allow_updates         = bool
    allowed_to_leave      = bool
    auto_connect          = number
    captive_portal        = number
    disable_auto_fallback = bool
    exclude_office_ips    = bool
    service_mode_v2       = object({ mode = string })
    support_url           = string
    switch_locked         = bool
    tunnel_protocol       = string # "masque" or "wireguard"
  }))
  default = []
}
