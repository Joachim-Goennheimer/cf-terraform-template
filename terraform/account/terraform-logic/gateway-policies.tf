# Zero Trust Gateway policies (secure web gateway / DNS filtering / network firewall).
# Gateway evaluates DNS policies first, then Network (L4), then HTTP. Within a type, lower
# precedence values are evaluated first.

resource "cloudflare_zero_trust_gateway_policy" "dns" {
  for_each = { for policy in var.gateway_dns_policies : policy.name => policy }

  account_id     = var.account_id
  name           = each.value.name
  description    = each.value.description
  enabled        = each.value.enabled
  action         = each.value.action
  precedence     = each.value.precedence
  filters        = ["dns"]
  traffic        = each.value.traffic
  identity       = each.value.identity
  device_posture = each.value.device_posture

  rule_settings = each.value.block_settings != null ? {
    block_page_enabled = each.value.block_settings.page_enabled
    block_reason       = each.value.block_settings.reason
  } : null
}

resource "cloudflare_zero_trust_gateway_policy" "network" {
  for_each = { for policy in var.gateway_network_policies : policy.name => policy }

  account_id     = var.account_id
  name           = each.value.name
  description    = each.value.description
  enabled        = each.value.enabled
  action         = each.value.action
  precedence     = each.value.precedence
  filters        = ["l4"]
  traffic        = each.value.traffic
  identity       = each.value.identity
  device_posture = each.value.device_posture
}

resource "cloudflare_zero_trust_gateway_policy" "http" {
  for_each = { for policy in var.gateway_http_policies : policy.name => policy }

  account_id     = var.account_id
  name           = each.value.name
  description    = each.value.description
  enabled        = each.value.enabled
  action         = each.value.action
  precedence     = each.value.precedence
  filters        = ["http"]
  traffic        = each.value.traffic
  identity       = each.value.identity
  device_posture = each.value.device_posture

  rule_settings = each.value.block_settings != null ? {
    block_page_enabled = each.value.block_settings.page_enabled
    block_reason       = each.value.block_settings.reason
  } : null
}
