# Zone: example-zone-shop.com
# Purpose: e-commerce shop. Shop-specific WAF rules and an Access-protected back office.

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
zone_id    = "<ZONE_ID_EXAMPLE_ZONE_SHOP_COM>" # Dashboard: zone Overview page -> API section
zone_name  = "example-zone-shop.com"

# ---------------------------------------------------------------------------
# Zone settings (keys are Cloudflare setting IDs)
# ---------------------------------------------------------------------------
zone_settings = {
  "ssl"                      = "strict"
  "min_tls_version"          = "1.2" # PCI DSS requires TLS 1.2 or higher
  "tls_1_3"                  = "on"
  "always_use_https"         = "on"
  "automatic_https_rewrites" = "on"
  "http3"                    = "on"
  "0rtt"                     = "off" # Keep off: checkout requests must never be replayable
  "early_hints"              = "off" # 103 Early Hints (asset preloading). Off: the zone has Access-protected apps, and cached hints can reveal their asset URLs to unauthenticated visitors
}

# ---------------------------------------------------------------------------
# DNS records
# ---------------------------------------------------------------------------
dns_records = {
  "apex" = {
    name    = "@"
    type    = "A"
    content = "192.0.2.40"
    ttl     = 1
    proxied = true
    comment = "Shop frontend origin"
  }
  "www" = {
    name    = "www"
    type    = "CNAME"
    content = "example-zone-shop.com"
    ttl     = 1
    proxied = true
    comment = "www -> apex"
  }
  "backoffice" = {
    name    = "backoffice"
    type    = "A"
    content = "192.0.2.41"
    ttl     = 1
    proxied = true # Must be proxied so Cloudflare Access can protect it
    comment = "Shop back office (protected by Access)"
  }
}

# ---------------------------------------------------------------------------
# WAF custom rules (evaluated top to bottom)
# ---------------------------------------------------------------------------
# Tip: test new rules with action = "log" before "block" or "managed_challenge".
waf_custom_rules = [
  {
    ref         = "block_cms_exploit_probing"
    description = "Block scans for common CMS admin/login endpoints (the shop does not use WordPress)"
    expression  = "http.request.uri.path in {\"/wp-login.php\" \"/xmlrpc.php\" \"/wp-admin/\"}"
    action      = "block"
    enabled     = true
  },
  {
    ref         = "block_unexpected_checkout_methods"
    description = "Checkout only accepts GET and POST"
    expression  = "starts_with(http.request.uri.path, \"/checkout\") and not (http.request.method in {\"GET\" \"POST\"})"
    action      = "block"
    enabled     = true
  },
  {
    ref         = "challenge_account_login"
    description = "Managed challenge on the customer login to slow down credential stuffing"
    expression  = "http.request.uri.path eq \"/account/login\" and http.request.method eq \"POST\""
    action      = "managed_challenge"
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
  "shop-operations" = {
    decision = "allow"
    include = {
      emails = [ # Named users only, no whole email domain
        "shop-manager@example-zone-a.com",
        "order-support@example-zone-a.com",
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

access_applications = {
  "Shop Back Office" = {
    type                      = "self_hosted"
    domain                    = "backoffice.example-zone-shop.com"
    session_duration          = "8h"
    auto_redirect_to_identity = false
    app_launcher_visible      = true
    allowed_idps              = []
    policies                  = ["shop-operations"]
    service_tokens            = []
  }
}
