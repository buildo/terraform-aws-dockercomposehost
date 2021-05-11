data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = <<-EOF
      package_update: true
      packages:
        - docker.io
        - docker-compose
      groups:
        - docker
      users:
        - default
        - name: ubuntu
          groups: docker
      write_files:
        - path: /etc/cwagentconfig/cwagentconfig.json
          encoding: b64
          content: ${base64encode(file(coalesce(var.cloudwatch_agent_config, "${path.module}/cwagentconfig.json")))}
          owner: root:root
          permissions: '0644'
      runcmd:
        - [sudo, docker, run, -d, --restart, always, -v, /etc/cwagentconfig:/etc/cwagentconfig, amazon/cloudwatch-agent:1.247347.6b250880]
    EOF
  }
}
