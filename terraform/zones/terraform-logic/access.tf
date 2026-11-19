# Cloudflare Access (Zero Trust) for applications hosted in this zone.
# Access objects are account-level in Cloudflare; names are prefixed with the zone name so
# that policies and tokens of different zones never collide in the dashboard.

locals {
  # Translate the simple include/exclude lists from tfvars into Access rule objects.
  access_policy_rules = {
    for key, policy in var.access_policies : key => {
      for part in ["include", "exclude"] : part => concat(
        [for email in policy[part].emails : { email = { email = email } }],
        [for domain in policy[part].email_domains : { email_domain = { domain = domain } }],
        [for range in policy[part].ip_ranges : { ip = { ip = range } }],
      )
    }
  }
}

resource "cloudflare_zero_trust_access_policy" "policies" {
  for_each = var.access_policies

  account_id = var.account_id
  name       = "${var.zone_name}: ${each.key}"
  decision   = each.value.decision
  include    = local.access_policy_rules[each.key].include
  exclude    = length(local.access_policy_rules[each.key].exclude) > 0 ? local.access_policy_rules[each.key].exclude : null
}

# Service tokens let machines (CI, monitoring) through Access via the
# CF-Access-Client-Id / CF-Access-Client-Secret request headers.
resource "cloudflare_zero_trust_access_service_token" "tokens" {
  for_each = var.access_service_tokens

  account_id = var.account_id
  name       = "${var.zone_name}: ${each.key}"
  duration   = each.value.duration

  # Create the replacement before deleting the old token, so clients are never left without one.
  lifecycle {
    create_before_destroy = true
  }
}

# One "Service Auth" (non_identity) policy per service token: lets the token through without an
# identity provider login.
resource "cloudflare_zero_trust_access_policy" "service_tokens" {
  for_each = cloudflare_zero_trust_access_service_token.tokens

  account_id = var.account_id
  name       = "${each.value.name} (service auth)"
  decision   = "non_identity"
  include    = [{ service_token = { token_id = each.value.id } }]
}

resource "cloudflare_zero_trust_access_application" "apps" {
  for_each = var.access_applications

  account_id                = var.account_id
  name                      = each.key
  type                      = each.value.type
  domain                    = each.value.domain
  session_duration          = each.value.session_duration
  auto_redirect_to_identity = each.value.auto_redirect_to_identity
  app_launcher_visible      = each.value.app_launcher_visible
  allowed_idps              = length(each.value.allowed_idps) > 0 ? each.value.allowed_idps : null

  # Service-token policies are evaluated first, then the identity policies in list order.
  policies = concat(
    [
      for idx, token in each.value.service_tokens : {
        id         = cloudflare_zero_trust_access_policy.service_tokens[token].id
        precedence = idx + 1
      }
    ],
    [
      for idx, policy in each.value.policies : {
        id         = cloudflare_zero_trust_access_policy.policies[policy].id
        precedence = length(each.value.service_tokens) + idx + 1
      }
    ],
  )
}
