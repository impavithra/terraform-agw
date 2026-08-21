#!/bin/bash
set -e

VM_IP=$1
VM_USER=$2
WAR_FILE=$3

if [ -z "$VM_IP" ] || [ -z "$VM_USER" ] || [ -z "$WAR_FILE" ]; then
  echo "Usage: ./deploy-vm1.sh <VM_IP> <VM_USER> <WAR_FILE>"
  exit 1
fi

echo "Deploying application to VM1..."

scp "$WAR_FILE" "$VM_USER@$VM_IP:/tmp/Amazon.war"

ssh "$VM_USER@$VM_IP" << 'EOF'
  sudo apt-get update
  sudo apt-get install -y tomcat10

  sudo rm -rf /var/lib/tomcat10/webapps/Amazon
  sudo rm -f /var/lib/tomcat10/webapps/Amazon.war

  sudo mv /tmp/Amazon.war /var/lib/tomcat10/webapps/Amazon.war

  sudo systemctl restart tomcat10
  sudo systemctl enable tomcat10
EOF

echo "VM1 deployment completed successfully."
