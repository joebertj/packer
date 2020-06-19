#!/bin/bash

sudo useradd -d /opt/nomad nomad
sudo mkdir /etc/nomad
sudo mkdir /opt/nomad
cat <<EOF > nomad-server.hcl
log_level = "INFO"
data_dir = "/opt/nomad"
server {
  enabled = true
  bootstrap_expect = 2
  server_join {
     retry_join = ["provider=aws tag_key=Name tag_value=devops1-devops", "provider=aws tag_key=Name tag_value=devops2-devops"]
   }

}
consul {
  address = "127.0.0.1:8500"
  auto_advertise = true
  server_auto_join = true
  client_auto_join = true
}
EOF
sudo mv nomad-server.hcl /etc/nomad
cat <<EOF > nomad-server.service
[Unit]
Description=Nomad Server
Wants=network-online.target
After=network-online.target consul-server.service
[Service]
Type=simple
User=nomad
ExecStart=/bin/sh -c "/usr/local/bin/nomad agent -config /etc/nomad/nomad-server.hcl"
Restart=always
RestartSec=10
LimitNOFILE=32768
[Install]
WantedBy=multi-user.target
EOF
sudo mv nomad-server.service /etc/systemd/system
sudo useradd -d /opt/consul consul
sudo mkdir /etc/consul
sudo mkdir /opt/consul
cat <<EOF > consul-server.json
{
  "data_dir": "/opt/consul",
  "log_level": "INFO",
  "server": true,
  "bootstrap_expect": 2,
  "retry_join": ["provider=aws tag_key=Name tag_value=devops1-devops", "provider=aws tag_key=Name tag_value=devops2-devops"]
}
EOF
sudo mv consul-server.json /etc/consul
cat <<EOF > consul-server.service
[Unit]
Description=Consul Server
Wants=network-online.target
After=network-online.target
[Service]
Type=simple
User=consul
ExecStart=/bin/sh -c "/usr/local/bin/consul agent -config-dir /etc/consul -bind \$(ifconfig | grep 10.60 | awk '{print \$2}')"
Restart=always
RestartSec=10
LimitNOFILE=32768
[Install]
WantedBy=multi-user.target
EOF
sudo mv consul-server.service /etc/systemd/system
sudo mkdir /opt/nomad/.aws
sudo cp ~/.aws/c* /opt/nomad/.aws
sudo mkdir /opt/consul/.aws
sudo cp ~/.aws/c* /opt/consul/.aws
sudo chown -R nomad: /etc/nomad
sudo chown -R nomad: /opt/nomad
sudo chown -R consul: /etc/consul
sudo chown -R consul: /opt/consul
sudo systemctl enable consul-server
sudo systemctl enable nomad-server
sudo cat <<EOF > limits.conf
*       soft    nofile  32768
*       hard    nofile  65536
root    soft    nofile  32768
root    hard    nofile  65536
EOF
sudo mv limits.conf /etc/security/
###
cat <<EOF > worker.nomad
job "worker" {
  datacenters = ["dc1"]

  group "web" {
    ephemeral_disk {
      migrate = false
      size    = "101"
      sticky  = false
    }
    update {
      max_parallel      = 1
      health_check      = "checks"
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "5m5s"
      auto_revert       = false
      canary            = 0
      stagger           = "5s"
    }
    restart {
      attempts = 60
      delay    = "30s"
    }
    reschedule {
      delay          = "30s"
      delay_function = "constant"
      unlimited      = true
    }
    count = 200
    task "nginx" {
      driver = "docker"

      config {
        image = "022663378596.dkr.ecr.ap-southeast-2.amazonaws.com/worker"
        port_map {
          http = 80
        }
      }

      resources {
        cpu    = 22 # MHz
        memory = 39 # MB
        network {
          mbits = 1
          port "http" {
          }
        }
      }
      
      service {
        name = "nginx"
        tags = ["urlprefix-/"]
        port = "http"
        check {
          name     = "alive"
          type     = "http"
          path     = "/"
          interval = "60s"
          timeout  = "30s"
        }
      }
    }
  }
}
EOF
cat <<EOF > fabio.nomad
job "fabio" {
  datacenters = ["dc1"]
  type = "system"
  priority = 100

  group "fabio" {
    task "fabio" {
      driver = "docker"
      config {
        image = "022663378596.dkr.ecr.ap-southeast-2.amazonaws.com/fabio"
        network_mode = "host"
      }

      resources {
        cpu    = 200
        memory = 128
        network {
          mbits = 20
          port "http" {
            static = 9999
          }
          port "ui" {
            static = 9998
          }
        }
      }
    }
  }
}
EOF

