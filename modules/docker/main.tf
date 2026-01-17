terraform {
  required_providers {
    skopeo2 = {
      source  = "bsquare-corp/skopeo2"
      version = "~> 1.1.0"
    }
  }
}

module "repositories" {
  source = "./ecr"

  for_each = {
    for v in local.image_info : v.key => v.name
  }

  name       = each.value
  account_id = var.account_id
}

resource "skopeo2_copy" "image" {
  for_each = {
    for v in local.images : v.key => v
  }

  source_image      = "docker://${each.key}:${each.value.tag}"
  destination_image = "docker://${module.repositories[each.value.name].url}:${each.value.tag}"

  insecure         = false
  copy_all_images  = true
  preserve_digests = true
  retries          = 3
  retry_delay      = 10
  keep_image       = true
}

locals {
  base_url = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"

  image_info = [
    { key = "golang", name = "golang" },
    { key = "node", name = "node" },
    { key = "postgis", name = "postgis/postgis" },
    { key = "redis", name = "redis" },
    { key = "tonistiigibinfmt", name = "tonistiigi/binfmt" },
  ]

  images = [
    { key = "golang", name = "golang", tag = "1.25.5" },
    { key = "golang-alpine", name = "golang", tag = "1.25.5-alpine" },
    { key = "node", name = "node", tag = "25.2.1" },
    { key = "node-alpine", name = "node", tag = "25.2.1-alpine" },
    { key = "postgis", name = "postgis/postgis", tag = "14-3.2" },
    { key = "redis", name = "redis", tag = "latest" },
    { key = "tonistiigibinfmt", name = "tonistiigi/binfmt", tag = "latest" },
  ]
}
