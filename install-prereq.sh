#!/bin/bash

sudo apt update
sudo apt update
sudo unattended-upgrade -d
sudo apt -y install sysstat
sudo apt -y install wget
sudo apt -y install unzip
sudo apt -y install jq
sudo apt -y install python
sudo apt -y install golang-go
go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login
sudo mv go/bin/docker-credential-ecr-login /usr/local/bin
rm -rf go
sudo apt -y install docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu

