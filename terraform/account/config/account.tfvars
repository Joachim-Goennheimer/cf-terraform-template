# Account-level configuration.
# Everything that applies to the Cloudflare account as a whole (not to a single zone or app).

# Find it in the dashboard URL (dash.cloudflare.com/<account-id>/...) or the account overview page.
# The account ID is an identifier, not a secret.
account_id = "<CLOUDFLARE_ACCOUNT_ID>"

# ---------------------------------------------------------------------------
# Zero Trust organization
# ---------------------------------------------------------------------------
zero_trust_organization = {
  name             = "Example Org"
  auth_domain      = "example-org.cloudflareaccess.com"
  session_duration = "24h"
  is_ui_read_only  = false # Set to true once the team works fully via Terraform
}

# ---------------------------------------------------------------------------
# Device profiles (WARP client)
# ---------------------------------------------------------------------------

# Default profile: baseline for all managed devices.
zero_trust_device_default_profile = {
  allow_mode_switch     = false                         # Users cannot switch away from the configured mode
  allow_updates         = false                         # Client updates are rolled out centrally (e.g. via MDM)
  allowed_to_leave      = false                         # Users cannot leave the Zero Trust organization
  switch_locked         = false                         # Users may pause WARP temporarily...
  auto_connect          = 600                           # ...but it reconnects automatically after 10 minutes
  captive_portal        = 180                           # Seconds WARP pauses to allow captive-portal login (hotels, airports)
  disable_auto_fallback = true                          # Fallback domains without a DNS server don't fall back to system DNS
  exclude_office_ips    = false                         # Don't auto-exclude Microsoft 365 IPs from the tunnel
  service_mode_v2       = { mode = "warp" }             # Full tunnel: DNS + network traffic through Gateway
  support_url           = "https://support.example.com" # Opened by the client's "Send feedback" button
  tunnel_protocol       = "masque"                      # HTTP/3 + TLS 1.3 (FIPS 140-3 cipher suite); Cloudflare's default
}

# Custom profiles: override the default for specific groups (from your identity provider).
# Every setting is listed explicitly; differences from the default profile are marked with <--.
zero_trust_device_custom_profiles = [
  {
    name                  = "Developers"
    description           = "More flexibility for engineering (mode switch, self-updates)"
    enabled               = true
    match                 = "any(identity.groups.name[*] in {\"developers\"})"
    precedence            = 100
    allow_mode_switch     = true # <-- may switch e.g. to DNS-only mode for debugging
    allow_updates         = true # <-- may install client updates themselves
    allowed_to_leave      = false
    switch_locked         = false
    auto_connect          = 0 # <-- no forced reconnect after pausing
    captive_portal        = 180
    disable_auto_fallback = true
    exclude_office_ips    = false
    service_mode_v2       = { mode = "warp" }
    support_url           = "https://support.example.com"
    tunnel_protocol       = "masque"
  },
  {
    name                  = "Contractors"
    description           = "Locked-down profile for external contractors"
    enabled               = true
    match                 = "any(identity.groups.name[*] in {\"contractors\"})"
    precedence            = 200
    allow_mode_switch     = false
    allow_updates         = false
    allowed_to_leave      = false
    switch_locked         = true # <-- WARP cannot be turned off
    auto_connect          = 0    # <-- irrelevant while switch_locked = true
    captive_portal        = 180
    disable_auto_fallback = true
    exclude_office_ips    = false
    service_mode_v2       = { mode = "warp" }
    support_url           = "https://support.example.com"
    tunnel_protocol       = "masque"
  },
]
