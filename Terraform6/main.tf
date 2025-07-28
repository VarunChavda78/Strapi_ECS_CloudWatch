# main.tf
provider "aws" {
  region = var.aws_region
}

# Load default VPC and subnets
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_subnet" "selected" {
  count = length(data.aws_subnets.default_vpc_subnets.ids)
  id    = data.aws_subnets.default_vpc_subnets.ids[count.index]
}

locals {
  alb_subnet_ids = distinct([
    for az in distinct([
      for s in data.aws_subnet.selected : s.availability_zone
    ]) : (
      [for s in data.aws_subnet.selected : s if s.availability_zone == az][0].id
    )
  ])
}
