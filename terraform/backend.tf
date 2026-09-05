terraform {
  # Partial config: pass bucket/key/lock table via backend.dev.hcl or backend.prod.hcl
  backend "s3" {}
}
