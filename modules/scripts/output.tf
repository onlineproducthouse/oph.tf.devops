output "content" {
  value = {
    for v in local.scripts : v.name => {
      key = v.key,
      url = "s3://${var.bucket_id}${v.key}",
      arn = "arn:aws:s3:::${var.bucket_id}${v.key}"
    }
  }
}
