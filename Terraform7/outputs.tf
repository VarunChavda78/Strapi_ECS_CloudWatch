output "alb_url" {
  description = "Public URL of the ALB to access Strapi"
  value       = aws_lb.strapi_alb.dns_name
}