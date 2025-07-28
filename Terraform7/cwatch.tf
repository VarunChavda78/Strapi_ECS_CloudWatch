resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "ecs-strapi-varun-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS service CPU utilization"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
  actions_enabled = false # later attach SNS
}

resource "aws_cloudwatch_dashboard" "ecs_dashboard" {
  dashboard_name = "StrapiECS"
  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name]
          ]
          period = 60
          stat   = "Average"
          region = var.aws_region
          title  = "ECS CPU Utilization"
        }
      }
    ]
  })
}
