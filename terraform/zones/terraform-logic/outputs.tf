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
