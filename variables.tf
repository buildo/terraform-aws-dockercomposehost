variable project_name {
  description = "Project name, used for namespacing things"
}

variable instance_type {
  default = "t3.nano"
}

variable ami {
  description = "Custom AMI, if empty will use latest Ubuntu LTS"
  default     = ""
}

variable volume_size {
  description = "Volume size"
  default     = 8
}

variable ssh_private_key {
  description = "Used to connect to the instance once created"
}

variable ssh_key_name {
  description = "Name of the key-pair on EC2 (aws-ireland, buildo-aws, ...)"
}

variable zone_id {
  description = "Route53 Zone ID"
  default     = ""
}

variable host_name {
  description = "DNS host name"
  default     = ""
}

variable in_open_ports {
  type    = list
  default = []
}

variable in_cidr_blocks {
  type    = list
  default = ["0.0.0.0/0"]
}

variable in_source_security_group {
  description = "Security group to receive SSH access"
  type        = string
  default     = ""
}

variable disk_utilization_alarm_threshold {
  description = "Disk occupation alarm threshold (% of disk utilization), for example 80.\nIf not set, the alarm won't be created"
  type        = number
  default     = 80
}

variable sns_alarm_enabled {
  description = "Determine if the cloudwatch alarm will be forwarded to the SNS topic provided or not"
  type        = bool
  default     = true
}

variable sns_topic_alarm_arn {
  type    = string
  default = "arn:aws:sns:eu-west-1:309416224681:bellosguardo"
}

variable cloudwatch_agent_config {
  type    = string
  default = ""
}
