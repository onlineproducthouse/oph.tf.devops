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

resource "skopeo2_copy" "main" {
  for_each = {
    for v in local.images.main : v.key => {
      name = v.name
      tag  = v.tag
    }
  }

  source_image      = "docker://${each.value.name}:${each.value.tag}"
  destination_image = "docker://${module.repositories[each.key].url}:${each.value.tag}"

  insecure         = false
  copy_all_images  = true
  preserve_digests = true
  retries          = 3
  retry_delay      = 10
  keep_image       = true
}

resource "skopeo2_copy" "alpine" {
  for_each = {
    for v in local.images.alpine : v.key => {
      name = v.name
      tag  = v.tag
    }
  }

  source_image      = "docker://${each.value.name}:${each.value.tag}"
  destination_image = "docker://${module.repositories[each.key].url}:${each.value.tag}"

  insecure         = false
  copy_all_images  = true
  preserve_digests = true
  retries          = 3
  retry_delay      = 10
  keep_image       = true
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

  images = {
    main = [
      { key = "golang", name = "golang", tag = "1.25.5" },
      { key = "node", name = "node", tag = "25.2.1" },
      { key = "postgis", name = "postgis/postgis", tag = "14-3.2" },
      { key = "redis", name = "redis", tag = "latest" },
      { key = "tonistiigibinfmt", name = "tonistiigi/binfmt", tag = "latest" },
    ]

    alpine = [
      { key = "golang", name = "golang", tag = "1.25.5-alpine" },
      { key = "node", name = "node", tag = "25.2.1-alpine" },
    ]
  }
}
