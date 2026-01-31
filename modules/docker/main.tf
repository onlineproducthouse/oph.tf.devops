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
    for v in local.repositories : v.key => v.name
  }

  name       = each.value
  account_id = var.account_id
}

resource "skopeo2_copy" "repo" {
  for_each = {
    for v in local.images : v.key => {
      repository = v.repository
      tag        = v.tag
    }
  }

  source_image      = "docker://${module.repositories[each.value.repository].name}:${each.value.tag}"
  destination_image = "docker://${module.repositories[each.value.repository].url}:${each.value.tag}"

  insecure         = false
  copy_all_images  = true
  preserve_digests = true
  retries          = 3
  retry_delay      = 10
  keep_image       = false
}

locals {
  base_url = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"

  repositories = [
    { key = "golang", name = "golang" },
    { key = "node", name = "node" },
    { key = "postgis", name = "postgis/postgis" },
    { key = "redis", name = "redis" },
    { key = "tonistiigibinfmt", name = "tonistiigi/binfmt" },
  ]

  images = [
    { key = "golang", repository = "golang", tag = "1.25.5" },
    { key = "golang-alpine", repository = "golang", tag = "1.25.5-alpine" },
    { key = "node", repository = "node", tag = "25.2.1" },
    { key = "node-alpine", repository = "node", tag = "25.2.1-alpine" },
    { key = "postgis", repository = "postgis", tag = "14-3.2" },
    { key = "redis", repository = "redis", tag = "8.4.0" },
    { key = "tonistiigibinfmt", repository = "tonistiigibinfmt", tag = "latest" },
  ]
}
