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
    for v in local.repositories : v.key => {
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
  keep_image       = false
  additional_tags  = v.include_alpine ? ["${each.value.name}:${each.value.tag}-alpine"] : []
}

locals {
  base_url = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"

  repositories = [
    { key = "golang", name = "golang", tag = "1.25.5", include_alpine = true },
    { key = "node", name = "node", tag = "25.2.1", include_alpine = true },
    { key = "postgis", name = "postgis/postgis", tag = "14-3.2", include_alpine = false },
    { key = "redis", name = "redis", tag = "8.4.0", include_alpine = false },
    { key = "tonistiigibinfmt", name = "tonistiigi/binfmt", tag = "latest", include_alpine = false },
  ]
}
