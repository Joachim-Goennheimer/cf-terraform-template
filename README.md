# Cloudflare Terraform Template

A blueprint for managing Cloudflare at enterprise scale with Terraform: many zones, account-wide
Zero Trust, and Workers applications. All changes go through pull requests and every scope has its
own isolated state.

All names, IDs and domains in this repository (`example-zone-a.com`, `my-example-workers-app`, …)
are placeholders. Replace them with your own values.

## Design principles

| Principle | How it is implemented |
|-----------|-----------------------|
| **Separate logic from configuration** | Resources are written once in `terraform-logic/` (templated with `for_each`). *What* gets built lives in `config/*.tfvars`. Day-to-day changes only touch tfvars. |
| **One state per scope** | The account, every zone, and every app each have their own state file. A broken apply in one zone cannot affect another, and plans stay small and fast. |
| **One file per product** | `dns.tf`, `waf.tf`, `access.tf`, `gateway-policies.tf`, … make code easy to find and review, and reduce merge conflicts. |
| **GitOps** | PR → `terraform plan` posted as a PR comment → review → merge → `terraform apply`. The dashboard is read-only for anything Terraform manages. |
| **Least privilege** | Each scope runs with its own narrowly scoped Cloudflare API token. |

## Repository structure

```
.
├── .github/workflows/
│   ├── terraform-reusable.yml              # Single reusable plan/apply pipeline
│   ├── terraform-account.yml               # Caller: account scope
│   ├── terraform-zone-<zone>.yml           # Caller: one per zone
│   ├── terraform-app-<app>.yml             # Caller: one per app
│   └── deploy-<app>.yml                    # wrangler deploy of the app's code
│
├── terraform/
│   ├── account/                            # Account-wide: Zero Trust, Gateway, ...
│   │   ├── config/                         #   account.tfvars + backend config
│   │   └── terraform-logic/                #   *.tf
│   ├── zones/                              # Shared logic for ALL zones
│   │   ├── config/                         #   <zone>.tfvars + <zone>.s3.tfbackend per zone
│   │   └── terraform-logic/                #   main.tf, dns.tf, waf.tf, access.tf, ...
│   └── apps/
│       └── my-example-workers-app/         # Per-app resources: D1, KV, R2, ...
│           ├── config/
│           └── terraform-logic/
│
└── apps/
    └── my-example-workers-app/             # Application code + wrangler.jsonc
```

Each `terraform-logic/` directory is a self-contained Terraform root module. Each `config/`
directory holds everything that is specific to one instance of that module: its variable
values (`.tfvars`) and where its state is stored (`.tfbackend`).
