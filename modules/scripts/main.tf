resource "aws_s3_object" "scripts" {
  for_each = {
    for v in local.scripts : v.name => v
  }

  bucket = var.bucket_id

  key                    = each.value.key
  source                 = each.value.source_path
  server_side_encryption = "AES256"
  etag                   = filemd5(each.value.source_path)
}

locals {
  scripts = [
    { name = "build-cloud", key = "/oph/scripts/build-cloud.sh", source_path = "${path.module}/content/build-cloud.sh" },
    { name = "build-container", key = "/oph/scripts/build-container.sh", source_path = "${path.module}/content/build-container.sh" },
    { name = "build-web", key = "/oph/scripts/build-web.sh", source_path = "${path.module}/content/build-web.sh" },

    { name = "codebuild-job", key = "/oph/scripts/codebuild.job.yml", source_path = "${path.module}/content/codebuild.job.yml" },

    { name = "deploy-cloud", key = "/oph/scripts/deploy-cloud.sh", source_path = "${path.module}/content/deploy-cloud.sh" },
    { name = "deploy-container-app", key = "/oph/scripts/deploy-container-app.sh", source_path = "${path.module}/content/deploy-container-app.sh" },
    { name = "deploy-container-db", key = "/oph/scripts/deploy-container-db.sh", source_path = "${path.module}/content/deploy-container-db.sh" },
    { name = "deploy-web", key = "/oph/scripts/deploy-web.sh", source_path = "${path.module}/content/deploy-web.sh" },

    { name = "load-env-vars", key = "/oph/scripts/load-env-vars.sh", source_path = "${path.module}/content/load-env-vars.sh" },
    { name = "local-env-vars", key = "/oph/scripts/local-env-vars.sh", source_path = "${path.module}/content/local-env-vars.sh" },
  ]
}
