# Zone: example-zone-status.net
# Purpose: public status page, hosted by a third-party status page provider.
# DNS-only zone: no proxied traffic.

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
zone_id    = "<ZONE_ID_EXAMPLE_ZONE_STATUS_NET>" # Dashboard: zone Overview page -> API section
zone_name  = "example-zone-status.net"

# ---------------------------------------------------------------------------
# Zone settings (keys are Cloudflare setting IDs)
# ---------------------------------------------------------------------------
# Settings only apply to proxied records. They are managed anyway so the zone is
# secure by default if a proxied record is added later.
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
  "status" = {
    name    = "status"
    type    = "CNAME"
    content = "example-org.statuspage-provider.example"
    ttl     = 300
    proxied = false # DNS only: the provider terminates TLS and must stay reachable if Cloudflare's proxy has an incident
    comment = "Status page (third-party provider)"
  }
}

# Not managed for this zone: waf_*, access_* (variables default to empty).
