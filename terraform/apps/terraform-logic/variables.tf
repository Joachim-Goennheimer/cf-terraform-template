# App-level variables, populated from ../config/<app>.tfvars. The SAME code is used for every app.
#
# Convention: setting attributes have NO defaults. Every value must be set explicitly in tfvars,
# so each setting is a deliberate decision. Only whole features default to {},
# which means "not managed by Terraform".
#
# Resources are keyed by a suffix (e.g. "staging-db"); the full name is "<app_name>-<suffix>".
# Location and jurisdiction can only be set when a resource is created: changing them later
# requires replacing the resource, which would DELETE ITS DATA. D1 databases and R2 buckets
# are protected with prevent_destroy, so such a plan fails instead (see d1.tf / r2.tf).

variable "account_id" {
  description = "Cloudflare account ID"
  type        = string
}

variable "app_name" {
  description = "Short app name, used as prefix for every resource of this app"
  type        = string
}

variable "d1_databases" {
  description = "D1 databases, keyed by name suffix"
  type = map(object({
    jurisdiction          = string # "eu", "us", "fedramp", or null for none
    primary_location_hint = string # "wnam", "enam", "weur", "eeur", "apac", "oc"; ignored if jurisdiction is set
  }))
  default = {}
}

variable "r2_buckets" {
  description = "R2 buckets, keyed by name suffix"
  type = map(object({
    jurisdiction  = string # "default", "eu", "us", "fedramp"
    location      = string # Hint: "wnam", "enam", "weur", "eeur", "apac", "oc"; null with a jurisdiction other than "default"
    storage_class = string # "Standard", "InfrequentAccess"
  }))
  default = {}
}

variable "kv_namespaces" {
  description = "Workers KV namespaces, keyed by name suffix"
  type = map(object({
    jurisdiction = string # "eu", "us", "fedramp", or null for none
  }))
  default = {}
}
