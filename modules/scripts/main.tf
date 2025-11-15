resource "aws_s3_object" "scripts" {
  for_each = {
    for v in local.scripts : v.name => v
  }

  bucket = var.bucket_id

  key                    = each.value.key
  source                 = each.value.source_path
  content_base64         = each.value.content_base64
  server_side_encryption = "AES256"
  etag                   = filemd5(each.value.source_path)
}

locals {
  scripts = [
    { name = "build_cloud", key = "/oph/scripts/build-cloud.sh", source_path = "./content/build-cloud.sh" },
    { name = "build_container", key = "/oph/scripts/build-container.sh", source_path = "./content/build-container.sh" },
    { name = "build_web", key = "/oph/scripts/build-web.sh", source_path = "./content/build-web.sh" },

    { name = "codebuild_job", key = "/oph/scripts/codebuild.job.yml", source_path = "./content/codebuild.job.yml" },

    { name = "deploy_cloud", key = "/oph/scripts/deploy-cloud.sh", source_path = "./content/deploy-cloud.sh" },
    { name = "deploy_container_app", key = "/oph/scripts/deploy-container-app.sh", source_path = "./content/deploy-container-app.sh" },
    { name = "deploy_container_db", key = "/oph/scripts/deploy-container-db.sh", source_path = "./content/deploy-container-db.sh" },
    { name = "deploy_web", key = "/oph/scripts/deploy-web.sh", source_path = "./content/deploy-web.sh" },

    { name = "load_env_vars", key = "/oph/scripts/load-env-vars.sh", source_path = "./content/load-env-vars.sh" },
    { name = "local_env_vars", key = "/oph/scripts/local-env-vars.sh", source_path = "./content/local-env-vars.sh" },
  ]
}
