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

resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "strapi-dashboard-varun"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          title = "ECS CPU Utilization (strapi-varun)",
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name]
          ],
          stat   = "Average",
          region = "us-east-2",
          period = 60
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          title = "ECS Memory Utilization (strapi-varun)",
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name]
          ],
          stat   = "Average",
          region = "us-east-2",
          period = 60
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          title = "Running Task Count (strapi-varun)",
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name]
          ],
          stat   = "Average",
          region = "us-east-2",
          period = 60
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          title = "Network In / Out (Bytes) (strapi-varun)",
          metrics = [
            ["ECS/ContainerInsights", "NetworkRxBytes", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name],
            [".", "NetworkTxBytes", ".", ".", ".", "."]
          ],
          stat   = "Sum",
          region = "us-east-2",
          period = 60
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 12,
        width  = 12,
        height = 6,
        properties = {
          title = "ALB Target Response Time (strapi-varun)",
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", local.alb_metric_name]
          ],
          stat   = "Average",
          region = "us-east-2",
          period = 60
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 12,
        width  = 12,
        height = 6,
        properties = {
          title = "Target Group Health Check (strapi-varun)",
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "TargetGroup", local.tg_metric_name, "LoadBalancer", local.alb_metric_name],
            [".", "UnHealthyHostCount", ".", ".", ".", "."]
          ],
          stat   = "Average",
          region = "us-east-2",
          period = 60
        }
      }
    ]
  })
}
