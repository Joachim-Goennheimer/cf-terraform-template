# IDs and names needed for the bindings in the app's wrangler.jsonc (apps/<app>/wrangler.jsonc).
# Retrieve with: terraform output -json

output "d1_databases" {
  description = "D1 databases: use `name` as database_name and `id` as database_id in wrangler.jsonc"
  value = {
    for key, db in cloudflare_d1_database.databases : key => {
      id   = db.id
      name = db.name
    }
  }
}

output "r2_buckets" {
  description = "R2 buckets: use `name` as bucket_name in wrangler.jsonc"
  value = {
    for key, bucket in cloudflare_r2_bucket.buckets : key => {
      name         = bucket.name
      jurisdiction = bucket.jurisdiction
    }
  }
}

output "kv_namespaces" {
  description = "KV namespaces: use `id` as id in wrangler.jsonc"
  value = {
    for key, ns in cloudflare_workers_kv_namespace.namespaces : key => {
      id    = ns.id
      title = ns.title
    }
  }
}
