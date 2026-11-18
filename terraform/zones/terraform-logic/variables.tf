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
