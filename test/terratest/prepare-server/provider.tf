terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.22.3"
    }
  }
}

provider "digitalocean" {
  token = var.do_token
}
