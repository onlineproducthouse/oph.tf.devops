output "scripts" {
  value = {
    for v in local.scripts : v.name => {
      key = v.key,
      url = "s3://${var.bucket_id}${v.key}",
    }
  }
}
