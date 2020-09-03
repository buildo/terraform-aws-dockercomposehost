# aws-dockercomposehost

Terraform module for creating AWS EC2 instances with Docker and Docker Compose installed.

## Resources

These resources are always created:
- A EC2 instance
- A Security Group
    - A Security Group Rule for port 22/tcp
    - A Security Group Rule for each port / port range specified in variable `in_open_ports`

These resources are created if their variable is set

| Resource | Variable |
|---|---|
| A CloudWatch Alarm for disk space utilization | disk_utilization_alarm_threshold |
| A Route53 record | zone_id && host_name |
|   |   |
