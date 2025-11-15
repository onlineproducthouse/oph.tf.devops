resource "aws_s3_bucket" "devops" {
  bucket = var.name
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.devops.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_configuration" {
  bucket = aws_s3_bucket.devops.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
