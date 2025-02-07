terraform {
  cloud {
    organization = "roadmap-sh"
    hostname     = "app.terraform.io"

    workspaces {
      name = "nodejs-service-deployment"
    }
  }
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}

provider "digitalocean" {}