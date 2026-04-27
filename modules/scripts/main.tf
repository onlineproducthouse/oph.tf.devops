resource "aws_s3_object" "scripts" {
  for_each = {
    for v in local.scripts : v.name => v
  }

  bucket                 = var.bucket_id
  key                    = each.value.key
  source                 = each.value.source_path
  server_side_encryption = "AES256"
  etag                   = filemd5(each.value.source_path)
}

locals {
  scripts = [
    { name = "cloud-codebuild", key = "/oph/scripts/cloud.codebuild.yml", source_path = "${path.module}/content/cloud.codebuild.yml" },
    { name = "container-codebuild", key = "/oph/scripts/container.codebuild.yml", source_path = "${path.module}/content/container.codebuild.yml" },
    { name = "web-codebuild", key = "/oph/scripts/web.codebuild.yml", source_path = "${path.module}/content/web.codebuild.yml" },

    { name = "load-env-vars", key = "/oph/scripts/load-env-vars.sh", source_path = "${path.module}/content/load-env-vars.sh" },
    { name = "local-env-vars", key = "/oph/scripts/local-env-vars.sh", source_path = "${path.module}/content/local-env-vars.sh" },
  ]
}
