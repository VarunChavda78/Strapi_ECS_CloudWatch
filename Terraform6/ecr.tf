# Create ECR repository
resource "aws_ecr_repository" "strapi_repo" {
  name                 = var.ecr_repo_name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = var.ecr_repo_name
  }
}

# Get AWS Account ID (for pushing image to ECR)
data "aws_caller_identity" "current" {}

# Push Docker image to ECR using local-exec
resource "null_resource" "docker_build_and_push" {
  provisioner "local-exec" {
    command = <<EOT
      echo "🔧 Building Docker image from ../Strapi-app..."
      docker build -t strapi-app:latest ../Strapi-app

      echo "🔐 Logging in to AWS ECR..."
      aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.us-east-2.amazonaws.com

      echo "🏷️ Tagging image with ECR repo..."
      docker tag strapi-app:latest ${aws_ecr_repository.strapi_repo.repository_url}:latest

      echo "📤 Pushing image to ECR..."
      docker push ${aws_ecr_repository.strapi_repo.repository_url}:latest
    EOT
  }

  depends_on = [aws_ecr_repository.strapi_repo]
}
