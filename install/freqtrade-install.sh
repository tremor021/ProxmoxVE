#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/freqtrade/freqtrade

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
  python3-pip \
  python3-venv \
  python3-dev \
  python3-pandas \
  git
wget -q http://prdownloads.sourceforge.net/ta-lib/ta-lib-0.4.0-src.tar.gz
tar xvzf ta-lib-0.4.0-src.tar.gz
cd ta-lib
sed -i.bak "s|0.00000001|0.000000000000000001 |g" src/ta_func/ta_utility.h
./configure --prefix=/usr/local
make
make install
ldconfig
msg_ok "Installed Dependencies"

msg_info "Setting up Freqtrade"
RELEASE=$(curl -s https://api.github.com/repos/freqtrade/freqtrade/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
$STD git clone https://github.com/freqtrade/freqtrade.git /opt/freqtrade
echo "${RELEASE}" >/opt/freqtrade_version.txt
cd /opt/freqtrade
$STD git checkout stable
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt
python3 -m pip install -e .
msg_ok "Done setting up Freqtrade"

msg_info "Creating Service"
{
    cd /opt/freqtrade
    python3 -m venv .venv
    source .venv/bin/activate
} >> ~/start.sh

cat <<EOF >/etc/systemd/system/freqtrade.service
[Unit]
Description=freqtrade Service
After=network.target

[Service]
ExecStart=/root/start.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF
freqtrade create-userdir --userdir user_data
freqtrade new-config --config user_data/config.json
systemctl enable -q --now freqtrade.service
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf ~/ta-lib*
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

motd_ssh
customize
