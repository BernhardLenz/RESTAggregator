

resource "aws_iam_role" "cloudwatch_events_role" {
  name               = "ecs-cloudwatch_events-role"
  assume_role_policy = data.aws_iam_policy_document.events_assume_role_policy.json
}

# allow events role to be assumed by events service 
data "aws_iam_policy_document" "events_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_events_role" {
  role = aws_iam_role.cloudwatch_events_role.id
  policy = data.aws_iam_policy_document.cloudwatch_events_role.json
}

# allow events role to run ecs tasks
data "aws_iam_policy_document" "cloudwatch_events_role" {
  statement {
    effect = "Allow"
    actions = ["ecs:RunTask"]
    ###################################################
    resources = ["arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.this.family}:*"]

    condition {
      test = "StringLike"
      variable = "ecs:cluster"
      values = [aws_ecs_cluster.this.arn]
    }
  }
}

resource "aws_iam_role_policy" "cloudwatch_events_passrole" {
  role = aws_iam_role.cloudwatch_events_role.id
  policy = data.aws_iam_policy_document.cloudwatch_events_passrole.json
}

# allow events role to pass role to task execution role and app role
data "aws_iam_policy_document" "cloudwatch_events_passrole" {
  statement {
    effect = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      aws_iam_role.execution_role.arn,
      aws_iam_role.task_role.arn
    ]
  }
}



resource "aws_cloudwatch_event_rule" "this" {
  name = "RestAggCloudwatchEventRule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "scheduled_task" {
  rule = aws_cloudwatch_event_rule.this.name
  target_id = "RestAggEcsScheduledTaskPrdUsEast1"
  arn = aws_ecs_cluster.this.arn
  role_arn = aws_iam_role.cloudwatch_events_role.arn
  input = "{}"

  ecs_target {
    task_count = 1
    task_definition_arn = aws_ecs_task_definition.this.arn
    launch_type = "FARGATE"
    platform_version = "LATEST"

    network_configuration {
      assign_public_ip = false
      security_groups = [aws_security_group.RestAggAppEcsServiceSecurityGroup.id]
      subnets = ["${aws_subnet.PrivateSubnetA.id}", "${aws_subnet.PrivateSubnetB.id}"]
    }
  }

  # allow the task definition to be managed by external ci/cd system
  lifecycle {
    ignore_changes = [
      ecs_target[0].task_definition_arn,
    ]
  }
}


