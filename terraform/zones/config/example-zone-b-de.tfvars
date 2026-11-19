# Zone: example-zone-b.de
# Purpose: German market website. A minimal zone: DNS, zone settings and managed WAF only.

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
zone_id    = "<ZONE_ID_EXAMPLE_ZONE_B_DE>" # Dashboard: zone Overview page -> API section
zone_name  = "example-zone-b.de"

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
  "early_hints"              = "on" # 103 Early Hints: browsers preload assets while the origin builds the page. Turn off if Access-protected apps are added
}

# ---------------------------------------------------------------------------
# DNS records
# ---------------------------------------------------------------------------
dns_records = {
  "apex" = {
    name    = "@"
    type    = "A"
    content = "192.0.2.30"
    ttl     = 1
    proxied = true
    comment = "German website origin (EU data center)"
  }
  "www" = {
    name    = "www"
    type    = "CNAME"
    content = "example-zone-b.de"
    ttl     = 1
    proxied = true
    comment = "www -> apex"
  }
}

# ---------------------------------------------------------------------------
# WAF (managed rulesets only; require the Pro plan or higher)
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
    description = "Cloudflare OWASP Core Ruleset"
    ruleset_id  = "4814384a9e5d4991b9815dcfc25d2f1f"
    expression  = "true"
    enabled     = true
  },
]

# Not managed for this zone: waf_custom_rules, access_* (variables default to empty).
