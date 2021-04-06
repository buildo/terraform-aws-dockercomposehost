data "aws_ami" "ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "instance" {
  ami                         = coalesce(var.ami, data.aws_ami.ami.image_id)
  instance_type               = var.instance_type
  key_name                    = var.ssh_key_name
  security_groups             = [aws_security_group.sg.name]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.instance.name

  user_data = templatefile("${path.module}/init.sh", {
    "cwagentconfig" = file(
      coalesce(var.cloudwatch_agent_config, "${path.module}/cwagentconfig.json")
    )
  })

  tags = {
    Name = var.project_name
  }

  root_block_device {
    volume_size = var.volume_size
  }
}

resource "aws_route53_record" "dns" {
  count = length(var.zone_id) > 0 && length(var.host_name) > 0 ? 1 : 0

  zone_id = var.zone_id
  name    = var.host_name
  type    = "A"
  ttl     = "300"
  records = [aws_instance.instance.public_ip]
}

resource "aws_iam_role_policy_attachment" "instance" {
  for_each = toset(concat(
    ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"],
    var.instance_profile_policy_arns,
  ))

  policy_arn = each.key
  role       = aws_iam_role.instance.id
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  name                  = "${var.project_name}-instance-profile"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_instance_profile" "instance" {
  name = var.project_name
  role = aws_iam_role.instance.name
}

resource "aws_cloudwatch_metric_alarm" "disk_full" {
  count               = var.disk_utilization_alarm_enabled == true ? 1 : 0
  alarm_name          = "${var.project_name}-${aws_instance.instance.id}-disk-full"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "disk_used_percent"
  namespace           = "System/Linux"
  period              = "60"
  statistic           = "Average"
  threshold           = var.disk_utilization_alarm_threshold
  alarm_description   = "This metric monitors disk utilization"
  alarm_actions       = var.disk_utilization_alarm_actions
  ok_actions          = var.disk_utilization_alarm_actions
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.instance.id
    path       = "/"
    device     = "overlay"
    fstype     = "overlay"
  }
}
