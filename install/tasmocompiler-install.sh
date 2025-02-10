#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies. Patience"
$STD apt-get install -y \
  curl \
  sudo \
  mc \
  python3-venv \
  npm
curl -fsSL -o get-platformio.py https://raw.githubusercontent.com/platformio/platformio-core-installer/master/get-platformio.py
$STD python3 get-platformio.py &> /dev/null
msg_ok "Installed Dependencies"

msg_info "Setup Node.js"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
$STD apt-get update
$STD apt-get install -y nodejs
msg_ok "Setup Node.js"

msg_info "Setting up TasmoCompiler. Patience"
RELEASE=$(curl -s https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
mkdir -p /usr/local/bin
ln -s ~/.platformio/penv/bin/platformio /usr/local/bin/platformio
ln -s ~/.platformio/penv/bin/pio /usr/local/bin/pio
ln -s ~/.platformio/penv/bin/piodebuggdb /usr/local/bin/piodebuggdb
useradd -m -p $(openssl passwd -1 "") -s /bin/bash -G sudo tasmota
su - tasmota
sudo echo "\n" | sudo npm install -g yarn
git clone https://github.com/benzino77/tasmocompiler
cd tas*
yarn install
yarn build
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
exit
msg_ok "Done setting up TasmoCompiler"
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/tasmocompiler.service
[Unit]
Description=TasmoCompiler Service
After=multi-user.target

[Service]
ExecStart=/usr/bin/node /home/tasmota/tasmocompiler/server/app.js &

[Install]
WantedBy=multi-user.target
EOF
sudo chmod 644 /lib/systemd/system/tasmocompiler.service
systemctl enable -q --now tasmocompiler.service
msg_ok "Created Service"
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
