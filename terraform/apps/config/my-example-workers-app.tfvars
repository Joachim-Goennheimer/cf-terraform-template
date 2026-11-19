# App: my-example-workers-app
# Resources the app's Worker needs (databases, storage, key-value). The Worker code itself is
# deployed by wrangler from apps/my-example-workers-app/, not by Terraform.
#
# Every resource exists once per environment, so staging can never touch production data.

account_id = "<CLOUDFLARE_ACCOUNT_ID>"
app_name   = "my-example-workers-app"

# Data residency: all data stays in the EU (e.g. for GDPR). Set the jurisdiction to null
# (D1/KV) or "default" (R2) if there is no residency requirement.

d1_databases = {
  "staging-db" = {
    jurisdiction          = "eu"
    primary_location_hint = null # Ignored when a jurisdiction is set
  }
  "production-db" = {
    jurisdiction          = "eu"
    primary_location_hint = null
  }
}

r2_buckets = {
  "staging-assets" = {
    jurisdiction  = "eu"
    location      = null # Location hints are an alternative to jurisdictions (e.g. "weur" with jurisdiction "default")
    storage_class = "Standard"
  }
  "production-assets" = {
    jurisdiction  = "eu"
    location      = null
    storage_class = "Standard"
  }
}

kv_namespaces = {
  "staging-cache" = {
    jurisdiction = "eu"
  }
  "production-cache" = {
    jurisdiction = "eu"
  }
}
