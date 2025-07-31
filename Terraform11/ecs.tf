resource "aws_ecs_cluster" "strapi_cluster" {
  name = "strapi-varun-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs-varun-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "codedeploy_role" {
  name = "strapi-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "codedeploy.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_role_policy" {
  role       = aws_iam_role.codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}


resource "aws_cloudwatch_log_group" "strapi_logs" {
  name              = "/ecs/strapi-varun"
  retention_in_days = 7
}


resource "aws_ecs_task_definition" "strapi_task" {
  family                   = "strapi-bluegreen"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi-varun-container"
      image     = "607700977843.dkr.ecr.us-east-2.amazonaws.com/strapi-varun-ecr-repo:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 1337
          hostPort      = 1337
        }
      ]
      environment = [
        { name = "DATABASE_CLIENT",      value = "postgres" },
        { name = "DATABASE_HOST",        value = "strapi-varun-db-instance.cbymg2mgkcu2.us-east-2.rds.amazonaws.com" },
        { name = "DATABASE_PORT",        value = "5432" },
        { name = "DATABASE_NAME",        value = "strapi" },
        { name = "DATABASE_USERNAME",    value = "strapi" },
        { name = "DATABASE_PASSWORD",    value = "Strapi123" },
        { name = "APP_KEYS",             value = "cd446k4vsItBPRI8hPr2bw==,dnXv48JDVT7LptYAFRHTaA==,8GggVZTb36gRw/88mHmWow==,h6G1JRVl104ltXtvvHpvtA==" },
        { name = "ADMIN_JWT_SECRET",     value = "6uoLuxGM+1TXcQKjCG4Rrg==" },
        { name = "API_TOKEN_SALT",       value = "OX3tBEnxGN9/uCw/1Jqz0Q==" },
        { name = "DATABASE_SSL",         value = "false" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.strapi_logs.name
          awslogs-region        = "us-east-2"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "strapi_service" {
  name            = "strapi-varun-service"
  cluster         = aws_ecs_cluster.strapi_cluster.id
  task_definition = aws_ecs_task_definition.strapi_task.arn_without_revision
  desired_count   = var.desired_count

  launch_type = "FARGATE"

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  network_configuration {
    subnets          = local.alb_subnet_ids
    assign_public_ip = true
    security_groups  = [aws_security_group.ecs_task_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi_blue_tg.arn
    container_name   = "strapi-varun-container"
    container_port   = var.container_port
  }

  depends_on = [aws_lb_listener.strapi_listener]
}


resource "aws_codedeploy_app" "strapi_codedeploy_app" {
  name = "strapi-bluegreen-app"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "strapi_codedeploy_group" {
  app_name               = aws_codedeploy_app.strapi_codedeploy_app.name
  deployment_group_name  = "strapi-bluegreen-deployment-group"
  service_role_arn       = aws_iam_role.codedeploy_role.arn
  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  deployment_style {
    deployment_type = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  blue_green_deployment_config {
    terminate_blue_instances_on_deployment_success {
      action = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }

    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.strapi_cluster.name
    service_name = aws_ecs_service.strapi_service.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.strapi_listener.arn]
      }

      target_group {
        name = aws_lb_target_group.strapi_blue_tg.name
      }

      target_group {
        name = aws_lb_target_group.strapi_green_tg.name
      }
    }
  }

  depends_on = [aws_iam_role_policy_attachment.codedeploy_role_policy]
}
