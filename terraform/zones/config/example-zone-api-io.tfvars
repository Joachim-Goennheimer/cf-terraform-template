# Zone: example-zone-api.io
# Purpose: public API for partners and mobile apps. API-specific WAF rules and an internal
# endpoint that only machines (service tokens) may call.

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
zone_id    = "<ZONE_ID_EXAMPLE_ZONE_API_IO>" # Dashboard: zone Overview page -> API section
zone_name  = "example-zone-api.io"

# ---------------------------------------------------------------------------
# Zone settings (keys are Cloudflare setting IDs)
# ---------------------------------------------------------------------------
zone_settings = {
  "ssl"                      = "strict"
  "min_tls_version"          = "1.2"
  "tls_1_3"                  = "on"
  "always_use_https"         = "on"  # Note: many API clients don't follow redirects; publish https:// URLs only
  "automatic_https_rewrites" = "off" # Only affects HTML; not relevant for a JSON API
  "http3"                    = "on"
  "0rtt"                     = "off" # API writes must never be replayable
  "early_hints"              = "off" # 103 Early Hints (asset preloading). Off: only useful for HTML pages, and the zone has Access-protected endpoints
}

# ---------------------------------------------------------------------------
# DNS records
# ---------------------------------------------------------------------------
dns_records = {
  "api" = {
    name    = "api"
    type    = "A"
    content = "192.0.2.50"
    ttl     = 1
    proxied = true
    comment = "API gateway origin"
  }
  "api-ipv6" = {
    name    = "api"
    type    = "AAAA"
    content = "2001:db8::50" # RFC 3849 documentation prefix
    ttl     = 1
    proxied = true
    comment = "API gateway origin (IPv6)"
  }
  "docs" = {
    name    = "docs"
    type    = "CNAME"
    content = "api-docs.docs-provider.example"
    ttl     = 1
    proxied = true
    comment = "Public API documentation (hosted docs provider)"
  }
}

# ---------------------------------------------------------------------------
# WAF custom rules (evaluated top to bottom)
# ---------------------------------------------------------------------------
# Tip: test new rules with action = "log" before "block" or "managed_challenge".
# Challenges don't work for API clients (no browser): use "block" for APIs.
waf_custom_rules = [
  {
    ref         = "block_unknown_api_versions"
    description = "Only /v1/ and /v2/ exist on the API host"
    expression  = "http.host eq \"api.example-zone-api.io\" and not starts_with(http.request.uri.path, \"/v1/\") and not starts_with(http.request.uri.path, \"/v2/\") and not starts_with(http.request.uri.path, \"/internal/\")"
    action      = "block"
    enabled     = true
  },
  {
    ref         = "block_non_json_writes"
    description = "Write requests must send a JSON body"
    expression  = "http.host eq \"api.example-zone-api.io\" and http.request.method in {\"POST\" \"PUT\" \"PATCH\"} and not any(http.request.headers[\"content-type\"][*] contains \"application/json\")"
    action      = "block"
    enabled     = true
  },
]

# ---------------------------------------------------------------------------
# WAF managed rulesets (require the Pro plan or higher)
# ---------------------------------------------------------------------------
waf_managed_rulesets = [
  {
    ref         = "cloudflare_managed_ruleset"
    description = "Cloudflare Managed Ruleset"
    ruleset_id  = "efb7b8c949ac4650a09736fc376e9aee"
    expression  = "true"
    enabled     = true
  },
  {
    ref         = "cloudflare_owasp_core_ruleset"
    description = "Cloudflare OWASP Core Ruleset (API host only)"
    ruleset_id  = "4814384a9e5d4991b9815dcfc25d2f1f"
    expression  = "http.host eq \"api.example-zone-api.io\"" # Scope a ruleset to specific hosts
    enabled     = true
  },
]

# ---------------------------------------------------------------------------
# Access (Zero Trust): machine-only endpoint
# ---------------------------------------------------------------------------
# No identity policies: only requests with a valid service token get through.
access_service_tokens = {
  "billing-batch-jobs" = {
    duration = "8760h" # 1 year; rotate before expiry
  }
}

access_applications = {
  "API Internal Endpoints" = {
    type                      = "self_hosted"
    domain                    = "api.example-zone-api.io/internal"
    session_duration          = "1h"
    auto_redirect_to_identity = false
    app_launcher_visible      = false # Not meant for humans
    allowed_idps              = []
    policies                  = []
    service_tokens            = ["billing-batch-jobs"]
  }
}
