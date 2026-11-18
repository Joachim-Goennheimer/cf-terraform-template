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

# ---------------------------------------------------------------------------
# Gateway policies
# ---------------------------------------------------------------------------
# Naming follows Cloudflare's recommended convention: <Who>-<Layer>-<Selector>-<Action>.
# Policies are based on Cloudflare's recommended policies:
#   https://developers.cloudflare.com/learning-paths/secure-internet-traffic/
#
# Category IDs below were verified against the Cloudflare API:
#   GET https://api.cloudflare.com/client/v4/accounts/{account_id}/gateway/categories
# Category IDs can change over time; re-check them against this endpoint when updating policies.
#
# Precedence ranges (a convention that keeps policy types apart and leaves room for inserts):
#   DNS 1000-1999 | Network 2000-2999 | HTTP 3000-3999

gateway_dns_policies = [
  {
    # Security categories (all subcategories of "Security threats", ID 21):
    #    68 Anonymizer                      178 Brand Embedding (beta)
    #    80 Command and Control & Botnet    187 Compromised Domain
    #    83 Cryptomining                    176 DGA Domains
    #   175 DNS Tunneling                   117 Malware
    #   131 Phishing                        188 Potentially unwanted software
    #   134 Private IP Address (*)          191 Scam
    #   151 Spam                            153 Spyware
    # (*) 134 blocks public domains that resolve to private IPs (DNS rebinding protection).
    #     Remove it if internal apps are published in public DNS with private IPs.
    name           = "All-DNS-SecurityCategories-Blocklist"
    description    = "Block security threats (malware, phishing, C2/botnet, ...) based on Cloudflare threat intelligence"
    enabled        = true
    action         = "block"
    precedence     = 1000
    traffic        = "any(dns.security_category[*] in {68 178 80 187 83 176 175 117 131 188 134 191 151 153})"
    identity       = ""
    device_posture = ""
    block_settings = { page_enabled = true, reason = "This domain is blocked because it poses a security risk." }
  },
  {
    # Content categories (top-level category + all of its subcategories):
    #    17 Questionable Content:  85 Deceptive Ads, 87 Drugs, 102 Hacking, 157 Militancy, Hate & Extremism,
    #                              135 Profanity, 138 Questionable Activities, 180 School Cheating,
    #                              162 Unreliable Information
    #    32 Security Risks:        169 New Domains, 177 Newly Seen Domains, 128 Parked & For Sale Domains
    #    15 Miscellaneous:         115 Login Screens, 119 Miscellaneous, 124 No Content,
    #                              141 URL Alias/Redirect, 161 Unreachable
    # Tip: roll out with action = "allow" first, check the logs for false positives, then switch to "block".
    name           = "All-DNS-ContentCategories-Blocklist"
    description    = "Block questionable content, security risks (e.g. new domains) and miscellaneous categories"
    enabled        = true
    action         = "block"
    precedence     = 1100
    traffic        = "any(dns.content_category[*] in {17 85 87 102 157 135 138 180 162 32 169 177 128 15 115 119 124 141 161})"
    identity       = ""
    device_posture = ""
    block_settings = { page_enabled = true, reason = "This domain is blocked by the company content policy." }
  },
]

gateway_network_policies = [
  {
    name           = "Contractors-NET-PrivateNetwork-Block"
    description    = "Contractors may not reach internal (RFC 1918) networks"
    enabled        = true
    action         = "block"
    precedence     = 2000
    traffic        = "net.dst.ip in {10.0.0.0/8 172.16.0.0/12 192.168.0.0/16}"
    identity       = "any(identity.groups.name[*] in {\"contractors\"})"
    device_posture = ""
  },
]

# Application TYPE IDs (app.type.ids) are a different list from the categories above:
#    16 Do Not Inspect    25 Artificial Intelligence
# Source: Cloudflare docs. Verify via
#   GET https://api.cloudflare.com/client/v4/accounts/{account_id}/gateway/app_types
gateway_http_policies = [
  {
    # Must come first: apps with certificate pinning break under TLS inspection.
    name           = "All-HTTP-Application-InspectBypass"
    description    = "Do not inspect applications that use certificate pinning"
    enabled        = true
    action         = "off"
    precedence     = 3000
    traffic        = "any(app.type.ids[*] in {16})" # 16 = Do Not Inspect
    identity       = ""
    device_posture = ""
    block_settings = null
  },
  {
    # Same security categories as All-DNS-SecurityCategories-Blocklist (see the ID list there).
    name           = "All-HTTP-SecurityRisks-Blocklist"
    description    = "Block security threats at the HTTP layer (also catches requests that bypass DNS)"
    enabled        = true
    action         = "block"
    precedence     = 3100
    traffic        = "any(http.request.uri.security_category[*] in {68 178 80 187 83 176 175 117 131 188 134 191 151 153})"
    identity       = ""
    device_posture = ""
    block_settings = { page_enabled = true, reason = "This website is blocked because it poses a security risk." }
  },
  {
    # Identity-based exception: evaluated before the general AI block below.
    name           = "AIPilot-HTTP-Application-Allow"
    description    = "Allow public AI tools for members of the AI pilot group"
    enabled        = true
    action         = "allow"
    precedence     = 3200
    traffic        = "any(app.type.ids[*] in {25})" # 25 = Artificial Intelligence
    identity       = "any(identity.groups.name[*] in {\"ai-pilot\"})"
    device_posture = ""
    block_settings = null
  },
  {
    name           = "All-HTTP-Application-Blocklist"
    description    = "Block public AI tools (shadow IT) for everyone else"
    enabled        = true
    action         = "block"
    precedence     = 3300
    traffic        = "any(app.type.ids[*] in {25})" # 25 = Artificial Intelligence
    identity       = ""
    device_posture = ""
    block_settings = { page_enabled = true, reason = "Public AI tools are not approved. Please use the company AI service." }
  },
]

# ---------------------------------------------------------------------------
# Gateway settings
# ---------------------------------------------------------------------------

# null = TLS inspection uses the Cloudflare Root CA. Set this to use a Gateway-managed
# certificate instead. Either certificate must be deployed to devices as a trusted root.
gateway_managed_certificate = null
# gateway_managed_certificate = {
#   validity_period_days = 1825 # 5 years; only applied on creation
#   activate             = true
# }

gateway_settings = {
  tls_decrypt_enabled        = true  # Required to apply HTTP policies to HTTPS traffic
  protocol_detection_enabled = false # Detect HTTP/HTTPS on non-standard ports
  activity_log_enabled       = true  # Write Gateway activity logs (what is logged: see gateway_logging)
  antivirus = {
    enabled_download_phase = true # Scan downloaded files
    enabled_upload_phase   = true # Scan uploaded files
    fail_closed            = true # Block files that cannot be scanned (safer default)
  }
  block_page = {
    enabled          = true
    mode             = "customized_block_page"
    name             = "Example Org Secure Web Gateway"
    header_text      = "Access blocked"
    footer_text      = "Contact the IT service desk if you think this is a mistake."
    logo_path        = "https://www.example.com/logo.png"
    background_color = "#1e3a5f"
    mailto_address   = "it-servicedesk@example.com"
    mailto_subject   = "Gateway block page inquiry"
    suppress_footer  = false
  }
}

gateway_logging = {
  redact_pii = true                                   # Remove user email/IP/device details from logs (privacy)
  dns        = { log_all = false, log_blocks = true } # Log only blocked DNS queries
  http       = { log_all = false, log_blocks = true } # Log only blocked HTTP requests
  l4         = { log_all = false, log_blocks = true } # Log only blocked network sessions
}
