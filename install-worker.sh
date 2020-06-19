#!/bin/bash

wget https://s3.amazonaws.com/aws-cli/awscli-bundle.zip
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws
rm awscli-bundle.zip
rm -rf awscli-bundle
wget https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
chmod +x aws-iam-authenticator
sudo mv aws-iam-authenticator /usr/local/bin/
wget https://releases.hashicorp.com/nomad/0.9.1/nomad_0.9.1_linux_amd64.zip
unzip nomad_0.9.1_linux_amd64.zip
chmod +x nomad
sudo mv nomad /usr/local/bin
rm nomad_0.9.1_linux_amd64.zip
wget https://releases.hashicorp.com/consul/1.5.1/consul_1.5.1_linux_amd64.zip
unzip consul_1.5.1_linux_amd64.zip
chmod +x consul
sudo mv consul /usr/local/bin
rm consul_1.5.1_linux_amd64.zip
mkdir ~/.docker
cat <<EOF > ~/.docker/config.json
{
        "credHelpers": {
                "022663378596.dkr.ecr.ap-southeast-2.amazonaws.com": "ecr-login"
        }
}
EOF
mkdir ~/.aws
cat <<EOF > ~/.aws/config
[default]
output = json
region = ap-southeast-2
EOF

