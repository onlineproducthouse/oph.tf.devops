locals {
  base_url = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com"

  image_info = [
    {
      key  = "golang"
      name = "golang"
      versions = {
        main   = "1.23.2"
        alpine = "1.23.2-alpine"
      }
    },
    {
      key  = "node"
      name = "node"
      versions = {
        main   = "22.13.1"
        alpine = "22.13.1-alpine3.21"
      }
    },
    {
      key  = "postgis"
      name = "postgis/postgis"
      versions = {
        main   = "14-3.2"
        alpine = null
      }
    },
    {
      key  = "redis"
      name = "redis"
      versions = {
        main   = "latest"
        alpine = null
      }
    },
    {
      key  = "tonistiigibinfmt"
      name = "tonistiigi/binfmt"
      versions = {
        main   = "latest"
        alpine = null
      }
    },
  ]
}

locals {
  images = {
    for v in local.image_info : v.key => {
      key  = v.key
      name = v.name

      versions = {
        main = v.versions.main == null ? null : {
          version = v.versions.main
          tag = {
            docker = "${v.name}:${v.versions.main}"
            ecr    = "${module.repositories[v.key].url}:${v.versions.main}"
          }
        }

        alpine = v.versions.alpine == null ? null : {
          version = v.versions.alpine
          tag = {
            docker = "${v.name}:${v.versions.alpine}"
            ecr    = "${module.repositories[v.key].url}:${v.versions.alpine}"
          }
        }
      }
    }
  }

  tags = chunklist(compact(flatten(concat(
    [for v in [for img in local.images : img.versions.main] : v == null ? null : [for tag in v.tag : tag]],
    [for v in [for img in local.images : img.versions.alpine] : v == null ? null : [for tag in v.tag : tag]]
  ))), 2)
}

module "repositories" {
  source = "./ecr"

  for_each = {
    for v in local.image_info : v.key => v
  }

  name = each.value.name
}

resource "skopeo2_copy" "images" {
  count = length(local.tags)

  source_image      = "docker://${local.tags[count.index][0]}"
  destination_image = "docker://${local.tags[count.index][1]}"

  insecure         = false
  copy_all_images  = true
  preserve_digests = true
  retries          = 3
  retry_delay      = 10
  keep_image       = false
}
