variable project_name {
  description = "Project name, used for namespacing things"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.nano"
  type        = string
}

variable "ami" {
  description = "Custom AMI. If empty will use latest Ubuntu LTS"
  default     = ""
  type        = string
}

variable "volume_size" {
  description = "Volume size of disk, in GiB"
  default     = 8
  type        = number
}

variable ssh_private_key {
  description = "The private key material of the key pair associated with the instance"
  type        = string
}

variable ssh_key_name {
  description = "Name of the key-pair on EC2 (aws-ireland, buildo-aws, ...)"
  type        = string
}

variable zone_id {
  description = "Route53 Zone ID"
  default     = ""
  type        = string
}

variable host_name {
  description = "DNS host name"
  default     = ""
  type        = string
}

variable "in_open_ports" {
  description = "A list of ingress ports that must be open (expect for 22, open by default).\nExamples:\n- [80,443]\n- [\"8080-8082\", 1234]"
  type        = list(any)
  default     = []
}

variable "in_cidr_blocks" {
  description = "A whitelist of CIDR blocks allowed to access to the machine ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable in_source_security_group {
  description = "Security group to receive SSH access"
  type        = string
  default     = ""
}

variable disk_utilization_alarm_threshold {
  description = "Disk occupation alarm threshold (% of disk utilization), default 80"
  type        = number
  default     = 80
}

variable disk_utilization_alarm_enabled {
  description = "Determine if the cloudwatch alarm will be created or not"
  type        = bool
  default     = true
}

variable disk_utilization_alarm_actions {
  description = "ARN of the actions to run when the cloudwatch alarm is triggered"
  type        = list(string)
  default     = ["arn:aws:sns:eu-west-1:309416224681:bellosguardo"]
}

variable "cloudwatch_agent_config" {
  description = "Cloudwatch agent config. If not provided, a default one will be used. (see [cloudwatch documentation](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html))"
  type        = string
  default     = ""
}

variable instance_profile_policy_arns {
  description = "A list of IAM policy ARNs to be associated to the instance profile"
  type        = list(string)
  default     = []
}
