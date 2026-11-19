# Cloudflare Terraform Template

> **Disclaimer:** This is a personal project. The author works at Cloudflare, but this repository
> is **not an official Cloudflare product, guide or recommendation**, and it is not supported,
> reviewed or endorsed by Cloudflare.
>
> The template is provided **"as is", without warranty of any kind**, express or implied,
> including fitness for a particular purpose, **by Cloudflare or the author**. It may contain
> errors, outdated information, or settings that are unsuitable for your environment. Review,
> understand and test everything carefully before you use it, especially in production. You are
> solely responsible for its use. Neither Cloudflare nor the author is liable for any damages
> arising from it.

A blueprint for managing Cloudflare at enterprise scale with Terraform: **one Cloudflare account
with 1–n zones**, account-wide Zero Trust, and Workers applications. All changes go through pull
requests and every scope has its own isolated state.

**Multiple accounts:** extend the setup by treating accounts the same way as zones. Use one
`config/<account>.tfvars` + `.s3.tfbackend` per account under `terraform/account/`, with a
dedicated state, workflow and API token each. Zones and apps already carry their own
`account_id`, so they can belong to different accounts.

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
| **Explicit configuration** | Settings have no hidden defaults: every value is set in tfvars, so each one is a deliberate decision. A whole feature left out of tfvars is simply not managed. |
| **One repository, no modules** | See below. |

### Why there are no Terraform modules

Modules are deliberately not used. In practice they are often overused: they add indirection,
versioning and release overhead, and make plans harder to read. They pay off mainly when
Terraform code is shared across multiple teams **and repositories**, which is not recommended
for Cloudflare infrastructure.

Reuse already comes from the structure itself: one `terraform-logic/` per scope type, applied to
many `config/` files. Keep the entire Cloudflare setup of an enterprise in **one repository** and
control who may change what with repository permissions and `CODEOWNERS`
(see [Teams and permissions](#teams-and-permissions)).

## Operating model

The setup assumes **trunk-based development** with **strict GitOps**:

- **`main` is the only source of truth.** Every change is a short-lived branch and a pull request
  against `main`. There are no long-lived environment branches.
- **Pull request = plan, merge = apply.** The plan is posted to the PR for review. Merging applies
  it. Terraform workflows have no manual trigger, so the only way to change infrastructure is a
  reviewed merge.
- **No edit permissions in the Cloudflare dashboard.** People get read-only roles, and only the
  CI tokens can change configuration. That is what makes the setup reliable:
  - The state never drifts, so a plan reviewed in a PR is still accurate when it is applied after
    the merge (apply re-plans instead of applying a saved plan file).
  - Every change has an author, a review and a history in Git, and `git revert` is the rollback.
- **Review every plan for `destroy`.** Deletions are intended only when they appear in the PR plan.
  Data stores (D1, R2) are additionally protected with `prevent_destroy`.

Break-glass access (e.g. disabling a WAF rule during an incident) should be a separate,
audited admin role. Afterwards, the same change is made in Git so the code matches reality again.

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
│   ├── backend-common.s3.tfbackend         # Shared state settings (bucket, endpoint, locking)
│   ├── account/                            # Account-wide: Zero Trust, Gateway
│   │   ├── config/                         #   account.tfvars + account.s3.tfbackend
│   │   └── terraform-logic/                #   zero-trust.tf, gateway-policies.tf, gateway-settings.tf
│   ├── zones/                              # Shared logic for ALL zones
│   │   ├── config/                         #   <zone>.tfvars + <zone>.s3.tfbackend per zone
│   │   └── terraform-logic/                #   zone-settings.tf, dns.tf, waf.tf, access.tf
│   └── apps/                               # Shared logic for ALL apps
│       ├── config/                         #   <app>.tfvars + <app>.s3.tfbackend per app
│       └── terraform-logic/                #   d1.tf, r2.tf, kv.tf
│
└── apps/
    └── my-example-workers-app/             # Application code + wrangler.jsonc (no code in this template)
```

Each `terraform-logic/` directory is a self-contained Terraform root module. Each `config/`
directory holds everything that is specific to one instance of that module: its variable
values (`.tfvars`) and where its state is stored (`.tfbackend`).

### Included examples

| Scope | Example | Shows |
|-------|---------|-------|
| Account | `account.tfvars` | Zero Trust organization, WARP device profiles, Gateway DNS/Network/HTTP policies, TLS inspection, logging |
| Zone | `example-zone-a.com` | Corporate site: all features, including email records (MX, SPF, DMARC) |
| Zone | `example-zone-b.de` | Minimal zone: DNS + managed WAF |
| Zone | `example-zone-c.co.uk` | Apex CNAME to an external host |
| Zone | `example-zone-shop.com` | Shop-specific WAF rules, Access-protected back office |
| Zone | `example-zone-api.io` | API settings and WAF rules, endpoint reachable only with service tokens |
| Zone | `example-zone-status.net` | DNS-only zone (third-party status page) |
| Zone | `example-zone-internal.dev` | Internal tools, each behind its own Access policy |
| App | `my-example-workers-app` | D1, R2, KV per environment with EU data residency |

**Terraform vs. Wrangler:** Terraform owns long-lived resources that hold data (D1, R2, KV).
Wrangler owns the Worker code, its bindings and routes (`apps/<app>/wrangler.jsonc`). Code deploys
stay fast and can never delete data.

## State management

Use the storage your organization already knows and operates. What matters is that state is
**managed centrally, kept secure, and backed up automatically**. HashiCorp's
[state security best practices](https://developer.hashicorp.com/terraform/language/manage-sensitive-data#state-security-best-practices)
and backend recommendations boil down to:

- **Remote and central:** never local files, never in Git (`.gitignore` excludes state files).
- **Locking**, so two runs can never write the same state at the same time.
- **Encryption at rest and in transit.**
- **Access control:** only CI and a few administrators can read state, with dedicated credentials.
  State contains secrets, e.g. the Access service token credentials in this template.
- **Audit logs** for state access, where the storage supports them.
- **Versioning or backups**, so a corrupted or deleted state can be restored.

All of these work equally well:

| Option | Terraform backend | Locking | Encryption at rest | History / backups |
|--------|-------------------|---------|--------------------|-------------------|
| **Cloudflare R2** (used in this template) | `s3` | `use_lockfile` | Automatic (AES-256) | No object versioning: back up on a schedule (see below) |
| Amazon S3 | `s3` | `use_lockfile` | `encrypt = true` / KMS | Bucket versioning |
| Google Cloud Storage | `gcs` | Built in | Default, or customer-managed keys | Object versioning |
| Azure Blob Storage | `azurerm` | Built in (blob leases) | Default, or customer-managed keys | Blob versioning / soft delete |
| HCP Terraform | `cloud` block | Built in | Built in | State versions in the UI |

Switching storage only changes the `backend` block in each `providers.tf` and the shared
`.tfbackend` file. With HCP Terraform you can also run plans and applies there instead of in
GitHub Actions; the repository structure stays the same.

### This template: Cloudflare R2

All state files live in one R2 bucket, accessed through Terraform's S3-compatible `s3` backend.
Each scope gets its own object key:

```
example-org-terraform-state/
├── account/terraform.tfstate
├── zones/<zone>/terraform.tfstate
└── apps/<app>/terraform.tfstate
```

Each scope's backend settings come from two files, which Terraform combines into one
configuration when you pass several `-backend-config` flags to `terraform init` (later files win
if both define the same setting):

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
runs cannot both acquire the lock.

**Backups:** R2 has no object versioning. Copy the state bucket to a separate backup bucket on a
schedule (e.g. a cron-triggered Worker or CI job). Protect the backups with an
[R2 bucket lock](https://developers.cloudflare.com/r2/buckets/bucket-locks/) retention rule.
Don't put a bucket lock on the live state bucket, because Terraform must overwrite state files.

## Getting started

### 1. State bucket

1. Create the bucket outside of Terraform, which avoids a chicken-and-egg problem:
   `npx wrangler r2 bucket create example-org-terraform-state`
2. Create an **R2 API token** (R2 → *Manage API tokens*) with **Object Read & Write**, scoped to
   that bucket only. Note the *Access Key ID* and *Secret Access Key*.
3. Set your bucket name and account ID in `terraform/backend-common.s3.tfbackend`.
4. Set up backups (see above).

### 2. Cloudflare API tokens (one per scope)

Create one [API token](https://developers.cloudflare.com/fundamentals/api/get-started/create-token/)
per scope. Following the principle of least privilege, each token gets **only** the permissions
its scope needs. No token has admin rights, so a leaked or misused token can only affect its
own scope.

| Token | Permissions |
|-------|-------------|
| Account | Account: *Zero Trust Edit*, *Access: Organizations, Identity Providers, and Groups Edit* |
| Zone (one per zone) | Zone (**only this zone**): *Zone Settings Edit*, *DNS Edit*, *Zone WAF Edit* · Account: *Access: Apps and Policies Edit*, *Access: Service Tokens Edit* |
| App (Terraform) | Account: *D1 Edit*, *Workers R2 Storage Edit*, *Workers KV Storage Edit* |
| App deploy (Wrangler) | Token template *Edit Cloudflare Workers* ([docs](https://developers.cloudflare.com/workers/ci-cd/external-cicd/github-actions/)), limited to your account and the app's zone, plus Account: *D1 Edit* for migrations |

**When you add products** (e.g. rate limiting rules, Load Balancing, Tunnels), extend the
permissions of the affected scope's token. A missing permission shows up as an
authentication/403 error in the PR plan. Permission names: see the
[permissions reference](https://developers.cloudflare.com/fundamentals/api/reference/permissions/).

**Access applications: zone or account scope?** This template manages Access applications in
the zone config, because conceptually they belong to the hostname they protect. Technically
they are account-level objects: reusable Access policies only exist at account level, and the
Zero Trust dashboard lists all applications account-wide. As a result, zone tokens need
account-level Access permissions, which also allow changes to other zones' Access applications.

Managing all Access applications and policies in the account scope instead is an equally valid
choice. Zone tokens then stay purely zone-scoped, and one team (e.g. security/IAM) owns all
access rules in one place. The price is that a hostname's configuration is split between two
places.

### 3. GitHub repository settings

| Setting | Value |
|---------|-------|
| Secrets | `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (R2 token) · `CLOUDFLARE_API_TOKEN_ACCOUNT` · `CLOUDFLARE_API_TOKEN_ZONE_<ZONE>` per zone (e.g. `…_ZONE_EXAMPLE_ZONE_A_COM`) · `CLOUDFLARE_API_TOKEN_APP_<APP>` · `CLOUDFLARE_API_TOKEN_DEPLOY_<APP>` |
| Variables | `CLOUDFLARE_ACCOUNT_ID` (used by the deploy workflow) |
| Branch protection on `main` | Require pull requests, approval by code owners, and passing `plan` checks. No direct pushes. This is the only approval gate: a merged PR is applied automatically. |

### 4. Replace placeholders

Replace every `<CLOUDFLARE_ACCOUNT_ID>`, `<ZONE_ID_…>` and `example-*` value in `config/`, and
delete the example zones and apps you don't need (each consists of its two config files and one
workflow). Zone IDs are on the zone's *Overview* page in the dashboard.

### 5. Existing resources

Configuration that already exists in Cloudflare must be imported before the first apply,
otherwise Terraform tries to create duplicates (and fails, e.g. for WAF entry point rulesets):

- Add the resource to tfvars, then import it with an
  [`import` block](https://developer.hashicorp.com/terraform/language/import) or `terraform import`.
- [`cf-terraforming`](https://github.com/cloudflare/cf-terraforming) generates Terraform
  configuration and import commands from an existing account, which helps with large zones.

### 6. Running Terraform locally

```bash
export AWS_ACCESS_KEY_ID="<r2-access-key-id>"         # R2 credentials (see note above)
export AWS_SECRET_ACCESS_KEY="<r2-secret-access-key>"
export CLOUDFLARE_API_TOKEN="<cloudflare-api-token>"

cd terraform/zones/terraform-logic
terraform init -reconfigure \
  -backend-config=../../backend-common.s3.tfbackend \
  -backend-config=../config/example-zone-a-com.s3.tfbackend
terraform plan -var-file=../config/example-zone-a-com.tfvars
```

**Always use `-reconfigure`.** All zones (and all apps) share one `terraform-logic/` directory,
and `.terraform/` remembers the backend of the last `init`. `-reconfigure` sets up the new
backend from scratch. Without it, Terraform offers to *migrate* the previous scope's state to the
new key, which would copy one zone's state over another's.

**Running `terraform apply` locally is strongly discouraged:** it bypasses review and breaks the
GitOps principle. Local runs are meant for first tests and for speeding up the import of an
existing Cloudflare setup. They should not be needed in daily work.

## Day-to-day workflow

1. Create a branch and change the relevant `config/*.tfvars` file (e.g. add a DNS record).
2. Open a pull request. CI runs `terraform plan` for every affected scope and posts it as a comment.
3. Review the plan, especially any `destroy` or `replace`.
4. Merge. CI runs `terraform apply` for the affected scopes.

Changes to a `terraform-logic/` directory plan and apply **every** scope that uses it, which is
intended: shared code affects all zones or apps.

## Adding a zone or app

| Add | Create |
|-----|--------|
| Zone `example.org` | `terraform/zones/config/example-org.tfvars` + `example-org.s3.tfbackend` (copy an existing zone) and `.github/workflows/terraform-zone-example-org.yml` (copy a zone caller, replace the names) |
| App `my-app` | `terraform/apps/config/my-app.tfvars` + `my-app.s3.tfbackend`, `.github/workflows/terraform-app-my-app.yml`, and `apps/my-app/` with its `wrangler.jsonc` and deploy workflow |

Then add the scope's API token as a GitHub secret. No Terraform code changes are needed.

## Conventions

- **File names:** zone `example-zone-a.com` → `example-zone-a-com.tfvars` / `.s3.tfbackend` /
  `terraform-zone-example-zone-a-com.yml` / state key `zones/example-zone-a-com/terraform.tfstate`.
- **Maps with stable keys** (DNS records, Access policies, data stores): adding or removing one
  entry never touches the others. Renaming a key recreates that entry.
- **Lists where order matters** (WAF rules): every rule has a stable `ref`.
- **Gateway policies:** `<Who>-<Layer>-<Selector>-<Action>` names, precedence ranges
  DNS 1000–1999 · Network 2000–2999 · HTTP 3000–3999.
- **Pinned versions:** the Cloudflare provider via `.terraform.lock.hcl` (committed), Terraform and
  Wrangler in the workflows, GitHub Actions by commit SHA.
- **Domains without email:** consider a null MX (`.`), `v=spf1 -all` and a DMARC `p=reject` record
  to prevent spoofing.

## Teams and permissions

How to split responsibilities depends heavily on the organizational structure of the
enterprise. **Don't overengineer it.** In most cases, the simplest model is the best one: any
team may open pull requests anywhere in the repository, and the central infrastructure platform
team (the Cloudflare experts) approves them. Split ownership further only where teams really
need to work autonomously.

A model that scales when that becomes necessary:

- **A central infrastructure team owns the repository**, including all `terraform-logic/`
  directories, the workflows and the account scope. Merges to `main` require code owner review.
- **Teams own their zones and apps.** A
  [`CODEOWNERS`](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
  file assigns their config files to them, so they can review and merge their own changes
  autonomously:

  ```
  # .github/CODEOWNERS (later rules take precedence)
  *                                            @example-org/cloudflare-platform
  /terraform/zones/config/example-zone-shop-*  @example-org/team-ecommerce
  /terraform/apps/config/my-example-workers-*  @example-org/team-app
  /apps/my-example-workers-app/                @example-org/team-app
  ```

- **Splitting a single zone between teams** should be the exception, only when really necessary
  (e.g. strict separation of duties). It uses the same pattern, more granular: several
  tfvars + state files for one zone (e.g. `example-zone-a-com-dns.tfvars` and
  `example-zone-a-com-security.tfvars`), each owned by a different team. Split only along
  resources that exist independently, such as DNS records or Access applications. Zone settings
  and the WAF rulesets (one entry point ruleset per phase and zone) must stay in exactly one
  state, otherwise the states overwrite each other.

## License

[MIT No Attribution (MIT-0)](LICENSE): use, copy and adapt this template freely, without
attribution. See also the disclaimer at the top of this README.
