# Zone: example-zone-a.com
# Purpose: global corporate website (main brand domain).

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
zone_id    = "<ZONE_ID_EXAMPLE_ZONE_A_COM>" # Dashboard: zone Overview page -> API section
zone_name  = "example-zone-a.com"

# ---------------------------------------------------------------------------
# Zone settings (keys are Cloudflare setting IDs)
# ---------------------------------------------------------------------------
zone_settings = {
  "ssl"                      = "strict" # Full (strict): encrypt to the origin AND validate its certificate
  "min_tls_version"          = "1.2"    # Reject TLS 1.0/1.1 clients
  "tls_1_3"                  = "on"
  "always_use_https"         = "on" # Redirect all HTTP requests to HTTPS
  "automatic_https_rewrites" = "on" # Rewrite http:// links in HTML to https:// where possible
  "http3"                    = "on"
  "0rtt"                     = "off" # 0-RTT can allow request replays; enable only if the origin is replay-safe
  "early_hints"              = "off" # 103 Early Hints (asset preloading). Off: the zone has Access-protected apps, and cached hints can reveal their asset URLs to unauthenticated visitors
}

# ---------------------------------------------------------------------------
# DNS records
# ---------------------------------------------------------------------------
# Keys are stable identifiers: rename a key = delete + recreate the record.
# Example values only: 192.0.2.0/24 (RFC 5737) and *.example hostnames are reserved for documentation.
dns_records = {
  "apex" = {
    name    = "@"
    type    = "A"
    content = "192.0.2.10"
    ttl     = 1
    proxied = true
    comment = "Corporate website origin (load balancer)"
  }
  "www" = {
    name    = "www"
    type    = "CNAME"
    content = "example-zone-a.com"
    ttl     = 1
    proxied = true
    comment = "www -> apex"
  }
  "mx-primary" = {
    name     = "@"
    type     = "MX"
    content  = "mx1.mail-provider.example"
    ttl      = 3600
    proxied  = false
    priority = 10
    comment  = "Primary mail exchanger"
  }
  "mx-secondary" = {
    name     = "@"
    type     = "MX"
    content  = "mx2.mail-provider.example"
    ttl      = 3600
    proxied  = false
    priority = 20
    comment  = "Secondary mail exchanger"
  }
  "spf" = {
    name    = "@"
    type    = "TXT"
    content = "\"v=spf1 include:_spf.mail-provider.example -all\""
    ttl     = 3600
    proxied = false
    comment = "SPF: only the mail provider may send mail for this domain"
  }
  "dmarc" = {
    name    = "_dmarc"
    type    = "TXT"
    content = "\"v=DMARC1; p=reject; rua=mailto:dmarc-reports@example-zone-a.com\""
    ttl     = 3600
    proxied = false
    comment = "DMARC: reject unauthenticated mail, send aggregate reports"
  }
  "cms" = {
    name    = "cms"
    type    = "A"
    content = "192.0.2.20"
    ttl     = 1
    proxied = true # Must be proxied so Cloudflare Access can protect it
    comment = "Content management system (protected by Access, see below)"
  }
}

# ---------------------------------------------------------------------------
# WAF custom rules (evaluated top to bottom)
# ---------------------------------------------------------------------------
# Tip: test new rules with action = "log" before "block" or "managed_challenge".
waf_custom_rules = [
  {
    ref         = "block_secret_file_probing"
    description = "Block probing for secrets and VCS metadata (.env, .git)"
    expression  = "(http.request.uri.path contains \"/.env\") or (http.request.uri.path contains \"/.git/\")"
    action      = "block"
    enabled     = true
  },
  {
    ref         = "challenge_admin_outside_allowed_countries"
    description = "Challenge requests to /admin from outside the main markets"
    expression  = "starts_with(http.request.uri.path, \"/admin\") and not (ip.src.country in {\"US\" \"DE\" \"GB\" \"FR\" \"JP\"})"
    action      = "managed_challenge"
    enabled     = true
  },
]

# ---------------------------------------------------------------------------
# WAF managed rulesets (require the Pro plan or higher)
# ---------------------------------------------------------------------------
# Ruleset IDs are public and identical for every customer:
#   https://developers.cloudflare.com/terraform/additional-configurations/waf-managed-rulesets/
waf_managed_rulesets = [
  {
    ref         = "cloudflare_managed_ruleset"
    description = "Cloudflare Managed Ruleset"
    ruleset_id  = "efb7b8c949ac4650a09736fc376e9aee"
    expression  = "true" # All requests in this zone
    enabled     = true
  },
  {
    ref         = "cloudflare_owasp_core_ruleset"
    description = "Cloudflare OWASP Core Ruleset"
    ruleset_id  = "4814384a9e5d4991b9815dcfc25d2f1f"
    expression  = "true"
    enabled     = true
  },
]

# ---------------------------------------------------------------------------
# Access (Zero Trust)
# ---------------------------------------------------------------------------
access_policies = {
  "employees" = {
    decision = "allow"
    include = {
      emails        = []
      email_domains = ["example-zone-a.com"] # Everyone with a company email address...
      ip_ranges     = []
    }
    exclude = {
      emails        = ["former-employee@example-zone-a.com"] # ...except explicitly excluded users
      email_domains = []
      ip_ranges     = []
    }
  }
}

access_service_tokens = {
  "uptime-monitoring" = {
    duration = "8760h" # 1 year; rotate before expiry
  }
}

access_applications = {
  "Corporate CMS" = {
    type                      = "self_hosted"
    domain                    = "cms.example-zone-a.com"
    session_duration          = "8h"
    auto_redirect_to_identity = false
    app_launcher_visible      = true
    allowed_idps              = []
    policies                  = ["employees"]
    service_tokens            = ["uptime-monitoring"] # External uptime monitor checks the CMS without a login
  }
}
