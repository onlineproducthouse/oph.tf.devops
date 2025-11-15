output "tech_stack" {
  value = {
    agile = ["Jira", "Confluence"]

    thirdparty = ["Cloudinary", "RedisLabs", "SendGrid", "ScaleGrid", "Twilio"]

    design = ["Confluence", "draw.io", "Excalidraw"]

    frontend = {
      languages  = ["html", "css", "javascript"]
      frameworks = ["bootstrap", "vue", "storybook", "react", "angular"]
    }

    backend = {
      languages  = ["go", "c#", "nodejs", "php", "python"]
      frameworks = ["fibre", "echo", "dotnetcore", "express"]
      databases  = ["postgres", "mssql", "mysql", "redis", "mongo", "cassandra", "dynamodb"]
      queues     = ["AWS SQS", "Rabbit MQ", "Kafka"]
    }

    devops = {
      container      = ["Docker", "ECR", "ECS", "Docker Compose", "Kubernetes"]
      storage        = ["AWS S3", "Cloudinary"]
      infrastructure = ["AWS", "Azure", "Heroku"]
      scm            = ["bitbucket", "github", "azure devops"]
      cicd           = ["CodeBuild", "CodePipelines", "Azure DevOps", "Azure Pipelines", "Jenkins", "Octopus"]

      os = ["linux", "windows", "mac"]

      cloud = {
        aws = [
          "IAM",
          "S3",
          "SSM",
          "ACM",
          "Route53",
          "VPC",
          "CodeStar",
          "CodeBuild",
          "CodePipeline",
          "DynamoDB",
          "ECR",
          "ECS",
          "ALB",
          "EC2",
          "ASG",
          "CloudWatch",
          "SQS",
          "SNS",
          "SES",
          "CloudFront",
        ]
      }
    }
  }
}
