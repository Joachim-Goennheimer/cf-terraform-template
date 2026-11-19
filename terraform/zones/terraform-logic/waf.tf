# WAF: custom rules and managed rulesets for the zone.
# Each phase has exactly one zone-level entry point ruleset. If one was already created in the
# dashboard, import it first (terraform import) instead of letting Terraform create a second one.
# Rules are evaluated in list order, so the variables are lists (not maps) on purpose.

resource "cloudflare_ruleset" "waf_custom" {
  count = length(var.waf_custom_rules) > 0 ? 1 : 0

  zone_id = var.zone_id
  name    = "Custom WAF rules"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules = [
    for rule in var.waf_custom_rules : {
      ref         = rule.ref
      description = rule.description
      expression  = rule.expression
      action      = rule.action
      enabled     = rule.enabled
    }
  ]
}

resource "cloudflare_ruleset" "waf_managed" {
  count = length(var.waf_managed_rulesets) > 0 ? 1 : 0

  zone_id = var.zone_id
  name    = "Managed WAF rulesets"
  kind    = "zone"
  phase   = "http_request_firewall_managed"

  rules = [
    for ruleset in var.waf_managed_rulesets : {
      ref               = ruleset.ref
      description       = ruleset.description
      expression        = ruleset.expression
      action            = "execute"
      enabled           = ruleset.enabled
      action_parameters = { id = ruleset.ruleset_id }
    }
  ]
}
