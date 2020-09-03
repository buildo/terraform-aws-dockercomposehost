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
    content     = file("docker-compose.yml")
    destination = "~/docker-compose.yml"
  }

  provisioner "file" {
    content     = var.init_script
    destination = "~/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/config"
    ]
  }

  provisioner "file" {
    source      = "${path.cwd}/config/"
    destination = "~/config/"
  }

  provisioner "remote-exec" {
    script = "${path.module}/docker-install.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "docker login quay.io -u ${var.quay_username} -p ${var.quay_password}",
      "chmod +x ./init.sh",
      "./init.sh"
    ]
  }
}

resource "aws_cloudwatch_metric_alarm" "disk-full" {
  count               = var.disk_utilization_alarm_threshold == 0 ? 0 : 1
  alarm_name          = "${var.project_name}-${aws_instance.instance.id}-disk-full"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "3"
  metric_name         = "DiskSpaceUtilization"
  namespace           = "System/Linux"
  period              = "60"
  statistic           = "Average"
  threshold           = var.disk_utilization_alarm_threshold
  alarm_description   = "This metric monitors disk utilization"
  alarm_actions       = [var.bellosguardo_sns_topic_arn]
  ok_actions          = [var.bellosguardo_sns_topic_arn]
  treat_missing_data  = "breaching"

  dimensions = {
    InstanceId = aws_instance.instance.id
    MountPath  = "/"
    Filesystem = "overlay"
  }
}

variable "bellosguardo_sns_topic_arn" {
  type    = string
  default = "arn:aws:sns:eu-west-1:309416224681:bellosguardo"
}

resource "aws_route53_record" "dns" {
  count = length(var.zone_id) > 0 && length(var.host_name) > 0 ? 1 : 0

  zone_id = var.zone_id
  name    = var.host_name
  type    = "A"
  ttl     = "300"
  records = [aws_instance.instance.public_ip]
}
