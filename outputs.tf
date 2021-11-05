output "message" {
  value = "The machine is now available at ${aws_instance.instance.public_ip}."
}

output "ssh_cmd" {
  value = "ssh -i ${var.ssh_private_key} ubuntu@${aws_instance.instance.public_ip}"
}

output "public_ip" {
  value = aws_instance.instance.public_ip
}

output "instance_id" {
  value = aws_instance.instance.id
}
