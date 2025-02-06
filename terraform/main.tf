data "digitalocean_images" "available" {
  filter {
    key    = "distribution"
    values = ["CentOS"]
  }
  filter {
    key    = "regions"
    values = ["fra1"]
  }
  filter {
    key    = "type"
    values = ["base"]
  }
  sort {
    key       = "created"
    direction = "desc"
  }
}

data "digitalocean_ssh_key" "do_ssh_key" {
  name = var.ssh_key_name
}

resource "digitalocean_droplet" "web" {
  image  = data.digitalocean_images.available.images[0].slug
  name   = "web-1"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.do_ssh_key.id
  ]
  tags = ["roadmapsh-web"]
}
