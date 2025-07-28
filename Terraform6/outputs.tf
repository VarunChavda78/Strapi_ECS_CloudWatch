output "alb_url" {
  description = "Public URL of the ALB to access Strapi"
  value       = aws_lb.strapi_alb.dns_name
}

output "ecr_image_url" {
  value = "${aws_ecr_repository.strapi_repo.repository_url}:latest"
}