# Zone: example-zone-c.co.uk
# Purpose: UK market website, hosted by an external provider. The apex is a CNAME to the
# provider's hostname, which Cloudflare resolves at the edge (CNAME flattening).

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
zone_id    = "<ZONE_ID_EXAMPLE_ZONE_C_CO_UK>" # Dashboard: zone Overview page -> API section
zone_name  = "example-zone-c.co.uk"

# ---------------------------------------------------------------------------
# Zone settings (keys are Cloudflare setting IDs)
# ---------------------------------------------------------------------------
zone_settings = {
  "ssl"                      = "strict" # Requires the hosting provider to present a valid certificate for this hostname
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
    type    = "CNAME"
    content = "uk-site.hosting-provider.example"
    ttl     = 1
    proxied = true
    comment = "Apex CNAME to the hosting provider (flattened by Cloudflare)"
  }
  "www" = {
    name    = "www"
    type    = "CNAME"
    content = "example-zone-c.co.uk"
    ttl     = 1
    proxied = true
    comment = "www -> apex"
  }
}

# ---------------------------------------------------------------------------
# WAF
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
]

waf_managed_rulesets = [
  {
    ref         = "cloudflare_managed_ruleset"
    description = "Cloudflare Managed Ruleset"
    ruleset_id  = "efb7b8c949ac4650a09736fc376e9aee"
    expression  = "true"
    enabled     = true
  },
]

# Not managed for this zone: access_* (variables default to empty).
