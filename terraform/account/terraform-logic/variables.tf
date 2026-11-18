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

# ---------------------------------------------------------------------------
# Gateway policies
# ---------------------------------------------------------------------------
# `identity` / `device_posture` are wirefilter expressions; use "" for "no condition".
# `block_settings` controls the block page for action = "block"; use null for other actions.

variable "gateway_dns_policies" {
  description = "Gateway DNS policies"
  type = list(object({
    name           = string
    description    = string
    enabled        = bool
    action         = string # e.g. "block", "allow", "safesearch", "override"
    precedence     = number
    traffic        = string # e.g. any(dns.security_category[*] in {68 80})
    identity       = string
    device_posture = string
    block_settings = object({
      page_enabled = bool
      reason       = string
    })
  }))
  default = []
}

variable "gateway_network_policies" {
  description = "Gateway Network (L4) policies"
  type = list(object({
    name           = string
    description    = string
    enabled        = bool
    action         = string # e.g. "block", "allow", "audit_ssh"
    precedence     = number
    traffic        = string # e.g. net.dst.ip in {10.0.0.0/8}
    identity       = string
    device_posture = string
  }))
  default = []
}

variable "gateway_http_policies" {
  description = "Gateway HTTP policies (block/allow/isolate require TLS inspection)"
  type = list(object({
    name           = string
    description    = string
    enabled        = bool
    action         = string # e.g. "block", "allow", "isolate", "off" (= Do Not Inspect)
    precedence     = number
    traffic        = string # e.g. any(app.type.ids[*] in {25})
    identity       = string
    device_posture = string
    block_settings = object({
      page_enabled = bool
      reason       = string
    })
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Gateway settings
# ---------------------------------------------------------------------------

variable "gateway_managed_certificate" {
  description = "Gateway-managed TLS inspection certificate (null = use the Cloudflare Root CA)"
  type = object({
    validity_period_days = number # Only applied on creation
    activate             = bool   # Make the certificate available at Cloudflare's edge
  })
  default = null
}

variable "gateway_settings" {
  description = "Gateway account settings (null = not managed)"
  type = object({
    tls_decrypt_enabled        = bool
    protocol_detection_enabled = bool
    activity_log_enabled       = bool
    antivirus = object({
      enabled_download_phase = bool
      enabled_upload_phase   = bool
      fail_closed            = bool
    })
    block_page = object({ # null = Cloudflare's default block page
      enabled          = bool
      mode             = string # "customized_block_page"
      name             = string
      header_text      = string
      footer_text      = string
      logo_path        = string
      background_color = string
      mailto_address   = string
      mailto_subject   = string
      suppress_footer  = bool
    })
  })
  default = null
}

variable "gateway_logging" {
  description = "Gateway activity logging per policy type (null = not managed)"
  type = object({
    redact_pii = bool
    dns        = object({ log_all = bool, log_blocks = bool })
    http       = object({ log_all = bool, log_blocks = bool })
    l4         = object({ log_all = bool, log_blocks = bool })
  })
  default = null
}
