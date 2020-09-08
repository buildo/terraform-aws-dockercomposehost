# aws-dockercomposehost

Terraform module for creating AWS EC2 instances with Docker and Docker Compose installed.

## Example

docker-compose.yml:
```yaml
version: '3'

services:
  hello:
    image: nginxdemos/hello
    ports:
      - "80:80"
```

main.tf:
```hcl
module "aws-dockercomposehost" {
  source = "git@github.com:/buildo/terraform-aws-dockercomposehost.git"

  project_name    = "project-name"
  ssh_key_name    = "existing-key"
  ssh_private_key = "~/.ssh/id_rsa_aws"

  in_open_ports = [80]
}

```

By default a custom cloud watch configuration will be used.
If you want to specify a different one, just give a value to the variable `var.cloudwatch_agent_config`

Example:

```hcl
module "aws-dockercomposehost" {
  source = "git@github.com:/buildo/terraform-aws-dockercomposehost.git"

  project_name    = "project-name"
  ssh_key_name    = "existing-key"
  ssh_private_key = "~/.ssh/id_rsa_aws"

  in_open_ports = [80]

  cloudwatch_agent_config = "cwagentconfig.json"
}
```

## Resources

These resources are always created:
- A EC2 instance
- A Security Group
    - A Security Group Rule for port 22/tcp
    - A Security Group Rule for each port / port range specified in variable `in_open_ports`
- A IAM Role called "${var.project_name}-ec2-cloudwatch-role"
- A IAM Profile called "${var.project_name}-cloudwatch-profile"

These resources are created if their variable is set

| Resource | Variable |
|---|---|
| A CloudWatch Alarm for disk space utilization | disk_utilization_alarm_threshold |
| A Route53 record | zone_id && host_name |
|   |   |

## Fixes/Ideas

- Missing data are treated as "breaching", but the cloudwatch agent needs time to begin to collect data. This way the alarm is always triggered. Solutions?
- Isn't better to have directly an AMI built with something (Packer?) with docker and docker-compose installed?
