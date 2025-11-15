output "arn" {
  value = aws_ecr_repository.ecr.arn
}

output "name" {
  value = aws_ecr_repository.ecr.name
}

output "id" {
  value = aws_ecr_repository.ecr.registry_id
}

output "url" {
  value = aws_ecr_repository.ecr.repository_url
}
