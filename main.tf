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
  iam_instance_profile        = aws_iam_instance_profile.profile.name

  tags = {
    Name = var.project_name
  }

  root_block_device {
    volume_size = var.volume_size
  }

  connection {
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.ssh_private_key)
  }

  provisioner "file" {
    source      = coalesce(var.cloudwatch_agent_config, "${path.module}/cwagentconfig.json")
    destination = "~/cwagentconfig"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o DPkg::options::=\"--force-confdef\" -o DPkg::options::=\"--force-confold\"",
      "sudo apt-get install -y docker.io docker-compose",
      "sudo usermod -aG docker $USER",
      "sudo mv ~/cwagentconfig /etc/cwagentconfig",
      "docker run -d --restart always -v /etc/cwagentconfig:/etc/cwagentconfig amazon/cloudwatch-agent"
    ]
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

resource "aws_iam_role_policy_attachment" "cloudwatch_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cloudwatch_role.id
}

data aws_iam_policy_document "assume_policy" {
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

resource "aws_iam_role" "cloudwatch_role" {
  name                  = "${var.project_name}-ec2-cloudwatch-role"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.assume_policy.json
}

resource "aws_iam_instance_profile" "profile" {
  name = "${var.project_name}-cloudwatch-profile"
  role = aws_iam_role.cloudwatch_role.name
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
