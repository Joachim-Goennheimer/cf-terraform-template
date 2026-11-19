# Outputs for zone-level resources.

output "dns_records" {
  description = "Managed DNS records, keyed like in tfvars"
  value = {
    for key, record in cloudflare_dns_record.records : key => {
      id      = record.id
      name    = record.name
      type    = record.type
      content = record.content
      proxied = record.proxied
    }
  }
}

output "access_applications" {
  description = "Access applications. The AUD tag is needed by origins that validate Access JWTs."
  value = {
    for key, app in cloudflare_zero_trust_access_application.apps : key => {
      id     = app.id
      domain = app.domain
      aud    = app.aud
    }
  }
}

# Retrieve with: terraform output -json access_service_tokens
# Store the values in the consuming system's secret store (e.g. CI secrets), never in git.
output "access_service_tokens" {
  description = "Access service token credentials (Client ID / Client Secret)"
  sensitive   = true
  value = {
    for key, token in cloudflare_zero_trust_access_service_token.tokens : key => {
      client_id     = token.client_id
      client_secret = token.client_secret
    }
  }
}
