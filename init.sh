#!/bin/sh

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold"
sudo apt-get install -y docker.io docker-compose
sudo usermod -aG docker ubuntu
sudo mkdir -p /etc/cwagentconfig/
sudo /bin/su -c 'cat > /etc/cwagentconfig/cwagentconfig.json << "EOF"
${cwagentconfig}
EOF'
sudo docker run -d --restart always -v /etc/cwagentconfig:/etc/cwagentconfig amazon/cloudwatch-agent:1.247347.5b250583
