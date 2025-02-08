#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/YuukanOO/seelf

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
  gnupg \
  git
wget -qO- https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor >/usr/share/keyrings/mongodb-server-8.0.gpg
echo "deb [signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] http://repo.mongodb.org/apt/debian $(grep '^VERSION_CODENAME=' /etc/os-release | cut -d'=' -f2)/mongodb-org/8.0 main" >/etc/apt/sources.list.d/mongodb-org-8.0.list
$STD apt-get update
$STD apt-get install mongodb-org -y
systemctl enable -q --now mongod
sleep 2
# MONGO_ADMIN_USER="admin"
#MONGO_ADMIN_PWD="$(openssl rand -base64 18 | cut -c1-13)"
#$STD mongosh <<EOF
#use admin
#db.createUser({
#  user: "$MONGO_ADMIN_USER",
#  pwd: "$MONGO_ADMIN_PWD",
#  roles: [{ role: "root", db: "admin" }]
#})
#quit()
#EOF
#{
#    echo "MongoDB Credentials"
#    echo "Mongo Database User: $MONGO_ADMIN_USER"
#    echo "Mongo Database Password: $MONGO_ADMIN_PWD"
#} >> ~/astroluma.creds
#
curl -s -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash &> /dev/null
source ~/.bashrc
$STD nvm install node
msg_ok "Installed Dependencies"

msg_info "Setting up Astroluma. Patience"
RELEASE=$(curl -s https://api.github.com/repos/Sanjeet990/Astroluma/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/Sanjeet990/Astroluma/archive/refs/tags/v${RELEASE}.tar.gz"
tar xzf v${RELEASE}.tar.gz
mv Astroluma-${RELEASE} /opt/astroluma
cd /opt/astroluma
npm install
npm install pm2 -g
cd client
npm run build
cd ../server
SECRET=$(openssl rand -hex 16)
{
    echo "MONGODB_URI=mongodb://localhost:27017/astroluma"
    echo "SECRET_KEY=$SECRET"
} >> .env
msg_ok "Done setting up seelf"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/astroluma.service
[Unit]
Description=seelf Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/astroluma/server
ExecStart=pm2 start /opt/astroluma/server/server.js
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now astroluma
msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f ~/v${RELEASE}.tar.gz
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize 