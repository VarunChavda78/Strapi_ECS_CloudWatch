# rds.tf
resource "aws_db_subnet_group" "strapi_db_subnet_group" {
  name       = "strapi-varun-db-subnet-group"
  subnet_ids = data.aws_subnets.default_vpc_subnets.ids

  tags = {
    Name = "strapi-db-subnet-group"
  }
}

resource "aws_security_group" "strapi_rds_sg" {
  name        = "strapi-varun-rds-sg"
  description = "Allow access to RDS from ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-varun-rds-sg"
  }
}
resource "aws_db_parameter_group" "strapi_postgres_param_group" {
  name        = "strapi-postgres-param-group-varun"
  family      = "postgres17"
  description = "Custom parameter group for Strapi Postgres"
 
  parameter {
    name  = "rds.force_ssl"
    value = "0"
  }
 
  tags = {
    Name = "strapi_postgres_param_group-varun"
  }
}
resource "aws_db_instance" "strapi_db" {
  identifier              = "strapi-varun-db-instance"
  engine                  = "postgres"
  engine_version          = "17.4"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_name                 = "strapi"
  username                = "strapi"
  password                = "Strapi123"
  port                    = 5432
  publicly_accessible     = false
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.strapi_rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.strapi_db_subnet_group.name
  parameter_group_name   = aws_db_parameter_group.strapi_postgres_param_group.name
  allow_major_version_upgrade   = true

  tags = {
    Name = "strapi-varun-db"
  }
}

