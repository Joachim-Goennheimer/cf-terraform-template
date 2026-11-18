# Zero Trust Gateway account settings: TLS inspection, antivirus, block page, logging.

# Optional Gateway-managed certificate for TLS inspection. If not created, Gateway uses the
# Cloudflare Root CA. Either way, the certificate must be trusted on user devices (e.g. via MDM).
resource "cloudflare_zero_trust_gateway_certificate" "managed" {
  count = var.gateway_managed_certificate != null ? 1 : 0

  account_id           = var.account_id
  validity_period_days = var.gateway_managed_certificate.validity_period_days # Only applied on creation
  activate             = var.gateway_managed_certificate.activate
}

resource "cloudflare_zero_trust_gateway_settings" "main" {
  count = var.gateway_settings != null ? 1 : 0

  account_id = var.account_id

  settings = {
    tls_decrypt        = { enabled = var.gateway_settings.tls_decrypt_enabled }
    protocol_detection = { enabled = var.gateway_settings.protocol_detection_enabled }
    activity_log       = { enabled = var.gateway_settings.activity_log_enabled }
    antivirus          = var.gateway_settings.antivirus
    block_page         = var.gateway_settings.block_page

    certificate = length(cloudflare_zero_trust_gateway_certificate.managed) > 0 ? {
      id = cloudflare_zero_trust_gateway_certificate.managed[0].id
    } : null
  }
}

# What Gateway writes to its activity logs, per policy type.
resource "cloudflare_zero_trust_gateway_logging" "main" {
  count = var.gateway_logging != null ? 1 : 0

  account_id = var.account_id
  redact_pii = var.gateway_logging.redact_pii

  settings_by_rule_type = {
    dns  = var.gateway_logging.dns
    http = var.gateway_logging.http
    l4   = var.gateway_logging.l4
  }
}
