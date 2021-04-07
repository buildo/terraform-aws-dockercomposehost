output "public_ip" {
  description = "Public IP address of EC2 instance created"
  value       = aws_instance.instance.public_ip
}

output "instance_id" {
  description = "Instance ID of EC2 instance"
  value = aws_instance.instance.id
}
