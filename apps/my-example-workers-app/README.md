# my-example-workers-app

Placeholder for a Cloudflare Workers application. This template contains no application code,
only the structure and configuration that connect an app to the Terraform setup.

## Who manages what

| What | Managed by | Where |
|------|------------|-------|
| Resources the app uses (D1, R2, KV) | Terraform | `terraform/apps/config/my-example-workers-app.tfvars` |
| Worker code, bindings, routes | Wrangler | this directory (`wrangler.jsonc`) |
| D1 schema | Wrangler migrations | `migrations/` (applied during deploy) |
| Secrets | `wrangler secret put` | never in git |

Terraform owns long-lived resources that hold data. Wrangler owns the code that changes with
every release. That keeps code deploys fast and stops them from deleting data.

## Adding your code

1. Add your Worker code under `src/` (entry point `src/index.ts`, see `main` in `wrangler.jsonc`),
   plus a `package.json` with a pinned `wrangler` version.
2. Run `terraform apply` for the app, then copy the IDs from `terraform output -json` into the
   bindings in `wrangler.jsonc`.
3. Generate binding types instead of writing them by hand: `npx wrangler types`.
4. Deploy: `npx wrangler deploy --env staging` (CI does this automatically, see `.github/workflows/`).
