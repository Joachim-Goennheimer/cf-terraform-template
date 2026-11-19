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
│   │   └── terraform-logic/                #   zone-settings.tf, dns.tf, waf.tf, access.tf, ...
│   └── apps/                               # Shared logic for ALL apps
│       ├── config/                         #   <app>.tfvars + <app>.s3.tfbackend per app
│       └── terraform-logic/                #   d1.tf, r2.tf, kv.tf, ...
│
└── apps/
    └── my-example-workers-app/             # Application code + wrangler.jsonc
```

Each `terraform-logic/` directory is a self-contained Terraform root module. Each `config/`
directory holds everything that is specific to one instance of that module: its variable
values (`.tfvars`) and where its state is stored (`.tfbackend`).

## State management (Cloudflare R2)

All state files live in one [R2](https://developers.cloudflare.com/r2/) bucket, accessed through
Terraform's S3-compatible `s3` backend. Each scope gets its own object key:

```
example-org-terraform-state/
├── account/terraform.tfstate
├── zones/<zone>/terraform.tfstate
└── apps/<app>/terraform.tfstate
```

Each scope uses a single `s3` backend. Its settings come from two files, which Terraform combines
into one configuration when you pass several `-backend-config` flags to `terraform init` (later
files win if both define the same setting):

- `terraform/backend-common.s3.tfbackend`: shared settings (bucket, R2 endpoint, locking, R2-specific flags). You set these once.
- `terraform/<scope>/config/<name>.s3.tfbackend`: only the state `key` for that scope.

**Credentials** are passed via the environment variables `AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`, never in files.

> **Why "AWS" names for R2?** Terraform's `s3` backend is built on the AWS SDK and only reads
> credentials from these fixed variable names. They simply hold your **R2** API token's Access
> Key ID and Secret Access Key, and nothing connects to AWS. Passing credentials via
> `-backend-config` instead is discouraged: Terraform would store them in plain text in
> `.terraform/` and in every plan file.

**Locking:** `use_lockfile = true` (Terraform ≥ 1.10) writes a `<key>.tflock` object using a
conditional write. R2 evaluates conditional `PutObject` requests atomically, so two concurrent
runs against the same state cannot both acquire the lock. No DynamoDB-style service is needed.

### One-time setup

1. **Create the state bucket.** Do this outside of Terraform, which avoids a chicken-and-egg problem:
   `npx wrangler r2 bucket create example-org-terraform-state`
2. **Create an R2 API token** (R2 → *Manage API tokens*) with **Object Read & Write**, scoped to
   that bucket only. Note the *Access Key ID* and *Secret Access Key*.
3. **Edit** `terraform/backend-common.s3.tfbackend` with your bucket name and account ID.
4. **Initialize** a scope (example: account):

   ```bash
   export AWS_ACCESS_KEY_ID="<r2-access-key-id>"         # R2 credentials (see note above)
   export AWS_SECRET_ACCESS_KEY="<r2-secret-access-key>"
   export CLOUDFLARE_API_TOKEN="<cloudflare-api-token>"

   cd terraform/account/terraform-logic
   terraform init \
     -backend-config=../../backend-common.s3.tfbackend \
     -backend-config=../config/account.s3.tfbackend
   terraform plan -var-file=../config/account.tfvars
   ```

> R2 does not support S3 object versioning. To keep state history, back up the bucket regularly,
> for example by copying it to a second bucket on a schedule.

### Using a different object store

The layout works with any backend that supports locking. Only the `backend` block in each
`providers.tf` and the shared `.tfbackend` file need to change:

| Provider | Service | Terraform backend | Locking |
|----------|---------|-------------------|---------|
| AWS | Amazon S3 | `s3` | `use_lockfile = true` (native) |
| Google Cloud | Cloud Storage (GCS) | `gcs` | Built in |
| Microsoft Azure | Azure Blob Storage | `azurerm` | Built in (blob leases) |
