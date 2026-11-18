terraform {
  # >= 1.10 is required for native S3 state locking (`use_lockfile`).
  required_version = ">= 1.10"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.28"
    }
  }

  # Partial configuration: all values are supplied at `terraform init` via
  # terraform/backend-common.s3.tfbackend + ../config/account.s3.tfbackend.
  backend "s3" {}
}

provider "cloudflare" {
  # Authentication via the CLOUDFLARE_API_TOKEN environment variable. Never commit tokens.
}
