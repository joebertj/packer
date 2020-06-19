#!/bin/bash

sudo mkdir /etc/nomad
sudo mkdir /opt/nomad
cat <<EOF > nomad-client.hcl
log_level = "INFO"
data_dir = "/opt/nomad"
client {
  enabled = true
  node_class = "node"
  server_join {
     retry_join = ["provider=aws tag_key=Name tag_value=devops1-devops", "provider=aws tag_key=Name tag_value=devops2-devops"]
  }
  options = {
    "docker.privileged.enabled" = "true"
    "docker.volumes.enabled" = "true"
  }
  gc_max_allocs = 200
}
plugin "docker" {
  config {
    auth {
      helper = "ecr-login"
    }
  }
}
consul {
  address = "127.0.0.1:8500"
  auto_advertise = true
  server_auto_join = true
  client_auto_join = true
}
EOF
sudo mv nomad-client.hcl /etc/nomad
cat <<EOF > nomad-client.service
[Unit]
Description=Nomad client
Wants=network-online.target
After=network-online.target consul-client.service
[Service]
Type=simple
User=root
ExecStart=/bin/sh -c "/usr/local/bin/nomad agent -config /etc/nomad/nomad-client.hcl"
Restart=always
RestartSec=10
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
sudo mv nomad-client.service /etc/systemd/system
sudo useradd -d /opt/consul consul
sudo mkdir /etc/consul
sudo mkdir /opt/consul
cat <<EOF > consul-client.json
{
  "data_dir": "/opt/consul",
  "log_level": "INFO",
  "server": false,
  "retry_join": ["provider=aws tag_key=Name tag_value=devops1-devops", "provider=aws tag_key=Name tag_value=devops2-devops"]
}
EOF
sudo mv consul-client.json /etc/consul
cat <<EOF > consul-client.service
[Unit]
Description=Consul Client
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=consul
ExecStart=/bin/sh -c "/usr/local/bin/consul agent -config-dir /etc/consul -bind \$(ifconfig | grep 10.60 | awk '{print \$2}')"
Restart=always
RestartSec=10
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
sudo mv consul-client.service /etc/systemd/system
sudo mkdir /opt/consul/.aws
sudo cp ~/.aws/c* /opt/consul/.aws
sudo chown -R consul: /etc/consul
sudo chown -R consul: /opt/consul
sudo mkdir /root/.docker
sudo cp ~/.docker/config.json /root/.docker
sudo mkdir /root/.aws
sudo cp ~/.aws/c* /root/.aws
sudo systemctl enable consul-client
sudo systemctl enable nomad-client
sudo cat <<EOF > limits.conf
*	soft	nofile	65536
*	hard	nofile	131072
root	soft	nofile	65536
root	hard	nofile	131072
EOF
sudo mv limits.conf /etc/security/

