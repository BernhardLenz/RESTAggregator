locals {
  container_name = "RestAggAppTaskContainer"
}

resource "aws_ecs_cluster" "this" {
  name = "RestAggEcsClusterPrdUsEast1"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecr_repository" "this" {
  name                 = "restagg"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/RestAggEcsClusterPrdUsEast1Logs"
}

data "aws_iam_policy_document" "execution_assume_role_policy" {
  statement {
    sid     = "AllowAssumeByEcsTasks"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "execution_role" {
  statement {
    sid    = "AllowECRPull"
    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]

    resources = [aws_ecr_repository.this.arn]
  }

  statement {
    sid    = "AllowECRAuth"
    effect = "Allow"

    actions = ["ecr:GetAuthorizationToken"]

    resources = ["*"]
  }

  statement {
    sid    = "AllowLogging"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "task_role" {
  statement {
    sid    = "AllowDescribeCluster"
    effect = "Allow"

    actions = ["ecs:DescribeClusters"]

    resources = [aws_ecs_cluster.this.arn]
  }
}

resource "aws_iam_role" "execution_role" {
  name               = "ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role_policy.json
}

resource "aws_iam_role_policy" "execution_role" {
  role   = aws_iam_role.execution_role.name
  policy = data.aws_iam_policy_document.execution_role.json
}

resource "aws_iam_role" "task_role" {
  name               = "ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role_policy.json
}

resource "aws_iam_role_policy" "task_role" {
  role   = aws_iam_role.task_role.name
  policy = data.aws_iam_policy_document.task_role.json
}

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.21.0"

  container_name  = local.container_name
  container_image = "${aws_ecr_repository.this.repository_url}:latest"

  port_mappings = [
    {
      containerPort = 3000
      hostPort      = 3000
      protocol      = "tcp"
    }
  ]

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-region        = "us-east-1"
      awslogs-group         = aws_cloudwatch_log_group.this.name
      awslogs-stream-prefix = "ecs-service"
    }
    secretOptions = null
  }

  environment = [{
    name  = "SECRET_WORD"
    value = "Hi!"
  }]
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.container_name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  container_definitions    = module.container_definition.json
  execution_role_arn       = aws_iam_role.execution_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
}

resource "aws_security_group" "RestAggAppEcsServiceSecurityGroup" {
  name   = "RestAggAppEcsServiceSecurityGroup"
  vpc_id = aws_vpc.this.id

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RestAggAppEcsServiceSecurityGroup"
  }
}


resource "aws_ecs_service" "this" {
  name            = "RestAggEcsServicePrdUsEast1"
  task_definition = aws_ecs_task_definition.this.id
  cluster         = aws_ecs_cluster.this.arn

  launch_type   = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets         = ["${aws_subnet.PrivateSubnetA.id}", "${aws_subnet.PrivateSubnetB.id}"]
    security_groups = ["${aws_security_group.RestAggAppEcsServiceSecurityGroup.id}"]

    assign_public_ip = false
  }
}

