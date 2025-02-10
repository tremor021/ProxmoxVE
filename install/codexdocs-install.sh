#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.codex.so/codex-docs

source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  gnupg
msg_ok "Installed Dependencies"

msg_info "Installing Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g yarn
msg_ok "Installed Node.js"

msg_info "Setup CodeX Docs"
RELEASE=$(curl -s https://api.github.com/repos/codex-team/codex.docs/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/codex-team/codex.docs/archive/refs/tags/v${RELEASE}.tar.gz"
tar zxf v${RELEASE}.tar.gz
mv codex.docs-${RELEASE}/ /opt/codexdocs
cd /opt/codexdocs
touch docs-config.local.yaml
$STD yarn install
PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
SECRET=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
cat <<EOF >/opt/codexdocs/docs-config.local.yaml
port: 3000
host: "0.0.0.0"
uploads:
  driver: "local"
  local:
    path: "./uploads"
  s3:
    bucket: "my-bucket"
    region: "eu-central-1"
    baseUrl: "http://docs-static.codex.so.s3-website.eu-central-1.amazonaws.com"
    keyPrefix: "/"
    accessKeyId: "my-access-key"
    secretAccessKey: "my-secret-key"
frontend:
  title: "CodeX Docs"
  description: "Free Docs app powered by Editor.js ecosystemt"
  startPage: ""
  misprintsChatId: "12344564"
  yandexMetrikaId: ""
  carbon:
    serve: ""
    placement: ""
  menu:
    - "Guides"
    - title: "CodeX"
      uri: "https://codex.so"

auth:
  password: $PASSWORD
  secret: $SECRET

hawk:
#  frontendToken: "123"
#  backendToken: "123"

database:
  driver: local # you can change database driver here. 'mongodb' or 'local'
  local:
    path: ./db
#  mongodb:
#    uri: mongodb://localhost:27017/docs
EOF
{
    echo "CodeX Docs Credentials"
    echo "Web UI password: $PASSWORD"
    echo "Secret: $SECRET"
} >> ~/codexdocs.creds
echo "${RELEASE}" >/opt/codexdocs_version.txt
msg_ok "Setup CodeX Docs"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/codexdocs.service
[Unit]
Description=CodeX Docs Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/codexdocs
ExecStart=/usr/bin/yarn start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now codexdocs.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -f v${RELEASE}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"