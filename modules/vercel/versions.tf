terraform {
  required_version = ">= 1.3.0"

  required_providers {
    vercel = {
      source  = "vercel/vercel"
      version = ">= 1.0.0"
    }
  }
}
