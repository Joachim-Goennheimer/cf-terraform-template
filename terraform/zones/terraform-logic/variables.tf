# Zone-level variables, populated from ../config/<zone>.tfvars.
#
# Convention: setting attributes have NO defaults. Every value must be set explicitly in tfvars,
# so each setting is a deliberate decision. Only whole features default to null / {},
# which means "not managed by Terraform".

variable "account_id" {
  description = "Cloudflare account ID that owns the zone"
  type        = string
}

variable "zone_id" {
  description = "Cloudflare zone ID. Zones are onboarded outside of Terraform; this module manages their configuration."
  type        = string
}

variable "zone_name" {
  description = "Zone (domain) name, e.g. example-zone-a.com. Used to build full DNS record names."
  type        = string
}

# ---------------------------------------------------------------------------
# Zone settings
# ---------------------------------------------------------------------------

variable "zone_settings" {
  description = "Zone settings keyed by Cloudflare setting ID, e.g. { ssl = \"strict\" } ({} = not managed)"
  type        = map(string)
  default     = {}

  # If zone settings are managed, the baseline below must be set explicitly for every zone.
  # Additional setting IDs are allowed.
  validation {
    condition = length(var.zone_settings) == 0 || length(setsubtract(
      ["ssl", "min_tls_version", "tls_1_3", "always_use_https", "automatic_https_rewrites", "http3", "0rtt", "early_hints"],
      keys(var.zone_settings)
    )) == 0
    error_message = "zone_settings must set: ssl, min_tls_version, tls_1_3, always_use_https, automatic_https_rewrites, http3, 0rtt, early_hints."
  }
}

# ---------------------------------------------------------------------------
# DNS
# ---------------------------------------------------------------------------

variable "dns_records" {
  description = "DNS records, keyed by a stable, unique identifier (e.g. \"www\", \"mx-primary\")"
  type = map(object({
    name     = string # Relative name ("www") or "@" for the zone apex
    type     = string # "A", "AAAA", "CNAME", "MX", "TXT", ...
    content  = string
    ttl      = number           # Seconds; 1 = automatic (required when proxied = true)
    proxied  = bool             # true = traffic goes through Cloudflare (only for A, AAAA, CNAME)
    priority = optional(number) # Exception to the no-defaults rule: only set for MX/SRV/URI records (default null)
    comment  = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# WAF
# ---------------------------------------------------------------------------

variable "waf_custom_rules" {
  description = "WAF custom rules, evaluated in list order ([] = not managed)"
  type = list(object({
    ref         = string # Stable, unique rule identifier, e.g. "block_secret_file_probing"
    description = string
    expression  = string # Rules language expression
    action      = string # "block", "managed_challenge", "js_challenge", "challenge", "log" (Enterprise)
    enabled     = bool
  }))
  default = []
}

variable "waf_managed_rulesets" {
  description = "Cloudflare managed rulesets to deploy ([] = not managed)"
  type = list(object({
    ref         = string
    description = string
    ruleset_id  = string # Public ruleset ID from the Cloudflare docs
    expression  = string # Which requests the ruleset applies to; "true" = all
    enabled     = bool
  }))
  default = []
}

# ---------------------------------------------------------------------------
# Access (Zero Trust)
# ---------------------------------------------------------------------------

variable "access_policies" {
  description = "Reusable Access policies for this zone's applications, keyed by policy name"
  type = map(object({
    decision = string # "allow", "deny", "bypass"
    # A user matches if ANY entry in include matches, unless ANY entry in exclude matches.
    # Use [] for selectors you don't need. Other selectors (IdP groups, device posture, geo, ...)
    # can be added in access.tf following the same pattern.
    include = object({
      emails        = list(string)
      email_domains = list(string)
      ip_ranges     = list(string)
    })
    exclude = object({
      emails        = list(string)
      email_domains = list(string)
      ip_ranges     = list(string)
    })
  }))
  default = {}
}

variable "access_service_tokens" {
  description = "Access service tokens for machine-to-machine access, keyed by token name"
  type = map(object({
    duration = string # e.g. "8760h" (1 year), or "forever" (not recommended)
  }))
  default = {}
}

variable "access_applications" {
  description = "Access applications protecting hostnames in this zone, keyed by application name"
  type = map(object({
    type                      = string       # "self_hosted"
    domain                    = string       # e.g. "cms.example-zone-a.com" or "cms.example-zone-a.com/admin"
    session_duration          = string       # e.g. "8h"
    auto_redirect_to_identity = bool         # true = skip the IdP selection page (only one IdP allowed)
    app_launcher_visible      = bool         # Show the application in the Access App Launcher
    allowed_idps              = list(string) # IdP IDs; [] = all IdPs configured in the account
    policies                  = list(string) # Keys of access_policies, in evaluation order
    service_tokens            = list(string) # Keys of access_service_tokens allowed in (evaluated first)
  }))
  default = {}
}
