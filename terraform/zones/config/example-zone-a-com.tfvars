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
  "early_hints"              = "on"
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
}
