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

  repositories = concat(var.copy_docker_repositories, [
    { key = "tonistiigibinfmt", name = "tonistiigi/binfmt" },
  ])

  images = concat(var.copy_docker_images, [
    { key = "tonistiigibinfmt", repository = "tonistiigibinfmt", tag = "latest" },
  ])
}
