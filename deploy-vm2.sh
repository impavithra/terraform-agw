#!/bin/bash
set -e

VM_IP=$1
VM_USER=$2
WAR_FILE=$3

if [ -z "$VM_IP" ] || [ -z "$VM_USER" ] || [ -z "$WAR_FILE" ]; then
  echo "Usage: ./deploy-vm2.sh <VM_IP> <VM_USER> <WAR_FILE>"
  exit 1
fi

echo "Deploying application to VM2 Docker Tomcat..."

scp "$WAR_FILE" "$VM_USER@$VM_IP:/tmp/Amazon.war"

ssh "$VM_USER@$VM_IP" << 'EOF'

sudo apt-get update
sudo apt-get install -y docker.io

sudo systemctl enable docker
sudo systemctl start docker

sudo mkdir -p /opt/tomcat/webapps
sudo mv /tmp/Amazon.war /opt/tomcat/webapps/Amazon.war

sudo docker rm -f tomcat-app || true

sudo docker run -d \
  --name tomcat-app \
  --restart always \
  -p 8080:8080 \
  -v /opt/tomcat/webapps/Amazon.war:/usr/local/tomcat/webapps/Amazon.war \
  tomcat:10.1-jdk17-temurin

EOF

echo "VM2 deployment completed successfully."
