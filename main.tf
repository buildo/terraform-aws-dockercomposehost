data "aws_ami" "ami" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "instance" {
  ami = "${coalesce(var.ami, data.aws_ami.ami.image_id)}"
  instance_type = "${var.instance_type}"
  key_name = "${var.ssh_key_name}"
  security_groups = ["${aws_security_group.sg.name}"]
  associate_public_ip_address = true

  tags {
    Name = "${var.project_name}"
  }

  root_block_device {
    volume_size = "${var.volume_size}"
  }

  connection {
    user = "ubuntu"
    private_key = "${file("${var.ssh_private_key}")}"
  }

  provisioner "file" {
    content = "${file("docker-compose.yml")}"
    destination = "~/docker-compose.yml"
  }

  provisioner "file" {
    content = "${var.init_script}"
    destination = "~/init.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/config"
    ]
  }

  provisioner "file" {
    source = "${path.cwd}/config/"
    destination = "~/config/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get install -y apt-transport-https ca-certificates",
      "sudo apt-key adv --keyserver hkp://ha.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D",
      "echo \"deb https://apt.dockerproject.org/repo ubuntu-xenial main\" | sudo tee /etc/apt/sources.list.d/docker.list",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y docker-engine",
      "sudo service docker start",
      "sudo usermod -aG docker $USER",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose"
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "docker login quay.io -u ${var.quay_username} -p ${var.quay_password}",
      "chmod +x ./init.sh",
      "docker run -itd --restart always quay.io/buildo/bellosguardo:${var.bellosguardo_target}",
      "./init.sh"
    ]
  }
}

resource "aws_cloudwatch_metric_alarm" "disk-full" {
  alarm_name                = "${var.project_name}-${aws_instance.instance.id}-disk-full"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "3"
  metric_name               = "DiskSpaceUtilization"
  namespace                 = "System/Linux"
  period                    = "60"
  statistic                 = "Average"
  threshold                 = "${var.disk_utilization_alarm_threshold}"
  alarm_description         = "This metric monitors disk utilization"
  alarm_actions = ["${lookup(var.bellosguardo_sns_topic_arn, var.bellosguardo_target)}"]
  ok_actions = ["${lookup(var.bellosguardo_sns_topic_arn, var.bellosguardo_target)}"]
  treat_missing_data = "breaching"
  dimensions {
    InstanceId = "${aws_instance.instance.id}"
    MountPath = "/"
    Filesystem = "overlay"
  }
}

variable "bellosguardo_sns_topic_arn" {
  type = "map"
  default = {
    buildo = "arn:aws:sns:eu-west-1:309416224681:bellosguardo"
    omnilab = "arn:aws:sns:eu-west-1:143727521720:bellosguardo"
  }
}

resource "aws_route53_record" "dns" {
  zone_id = "${var.zone_id}"
  name = "${var.host_name}"
  type = "A"
  ttl = "300"
  records = ["${aws_instance.instance.public_ip}"]
}
