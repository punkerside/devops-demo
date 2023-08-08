data "aws_region" "main" {}
data "aws_caller_identity" "main" {}

data "aws_ecs_cluster" "main" {
  cluster_name = var.name
}

data "aws_vpc" "main" {
  tags = {
    Name   = var.name
  }
}

data "aws_lb_target_group" "main" {
  name = var.name
}

data "aws_iam_policy_document" "main" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com", "ecs.amazonaws.com"]
    }
  }
}

data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  tags = {
    Tier = "private"
  }
}