# Zone: example-zone-internal.dev
# Purpose: internal tools for employees. Every hostname is protected by Cloudflare Access.
# Note: .dev is on the HSTS preload list, so browsers only connect over HTTPS.

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
zone_id    = "<ZONE_ID_EXAMPLE_ZONE_INTERNAL_DEV>" # Dashboard: zone Overview page -> API section
zone_name  = "example-zone-internal.dev"

# ---------------------------------------------------------------------------
# Zone settings (keys are Cloudflare setting IDs)
# ---------------------------------------------------------------------------
zone_settings = {
  "ssl"                      = "strict"
  "min_tls_version"          = "1.2"
  "tls_1_3"                  = "on"
  "always_use_https"         = "on"
  "automatic_https_rewrites" = "on"
  "http3"                    = "on"
  "0rtt"                     = "off"
  "early_hints"              = "off" # 103 Early Hints (asset preloading). Off: the zone has Access-protected apps, and cached hints can reveal their asset URLs to unauthenticated visitors
}

# ---------------------------------------------------------------------------
# DNS records
# ---------------------------------------------------------------------------
# All tools must be proxied so Cloudflare Access can protect them.
dns_records = {
  "wiki" = {
    name    = "wiki"
    type    = "A"
    content = "192.0.2.70"
    ttl     = 1
    proxied = true
    comment = "Internal wiki"
  }
  "grafana" = {
    name    = "grafana"
    type    = "A"
    content = "192.0.2.71"
    ttl     = 1
    proxied = true
    comment = "Monitoring dashboards"
  }
  "ci" = {
    name    = "ci"
    type    = "A"
    content = "192.0.2.72"
    ttl     = 1
    proxied = true
    comment = "CI/CD server"
  }
}

# ---------------------------------------------------------------------------
# WAF managed rulesets (require the Pro plan or higher)
# ---------------------------------------------------------------------------
# Defense in depth: Access authenticates users, the WAF still inspects their requests.
waf_managed_rulesets = [
  {
    ref         = "cloudflare_managed_ruleset"
    description = "Cloudflare Managed Ruleset"
    ruleset_id  = "efb7b8c949ac4650a09736fc376e9aee"
    expression  = "true"
    enabled     = true
  },
]

# ---------------------------------------------------------------------------
# Access (Zero Trust)
# ---------------------------------------------------------------------------
access_policies = {
  "all-employees" = {
    decision = "allow"
    include = {
      emails        = []
      email_domains = ["example-zone-a.com"] # Corporate email domain
      ip_ranges     = []
    }
    exclude = {
      emails        = []
      email_domains = []
      ip_ranges     = []
    }
  }
  "platform-engineering" = {
    decision = "allow"
    include = {
      emails = [
        "platform-lead@example-zone-a.com",
        "sre-oncall@example-zone-a.com",
      ]
      email_domains = []
      ip_ranges     = []
    }
    exclude = {
      emails        = []
      email_domains = []
      ip_ranges     = []
    }
  }
}

access_service_tokens = {
  "ci-deploy-webhook" = {
    duration = "8760h" # 1 year; rotate before expiry
  }
}

access_applications = {
  "Internal Wiki" = {
    type                      = "self_hosted"
    domain                    = "wiki.example-zone-internal.dev"
    session_duration          = "24h"
    auto_redirect_to_identity = false
    app_launcher_visible      = true
    allowed_idps              = []
    policies                  = ["all-employees"]
    service_tokens            = []
  }
  "Grafana" = {
    type                      = "self_hosted"
    domain                    = "grafana.example-zone-internal.dev"
    session_duration          = "8h"
    auto_redirect_to_identity = false
    app_launcher_visible      = true
    allowed_idps              = []
    policies                  = ["platform-engineering"]
    service_tokens            = []
  }
  "CI Server" = {
    type                      = "self_hosted"
    domain                    = "ci.example-zone-internal.dev"
    session_duration          = "8h"
    auto_redirect_to_identity = false
    app_launcher_visible      = true
    allowed_idps              = []
    policies                  = ["platform-engineering"]
    service_tokens            = ["ci-deploy-webhook"] # Source-control webhooks reach the CI without a login
  }
}
