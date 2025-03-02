#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/twentyhq/twenty

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
    gpg \
    curl \
    sudo \
    mc \
    redis
msg_ok "Installed Dependencies"

msg_info "Setting up Node.js Repository"
mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" >/etc/apt/sources.list.d/nodesource.list
msg_ok "Set up Node.js Repository"

msg_info "Setting up PostgreSQL Repository"
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
echo "deb https://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" >/etc/apt/sources.list.d/pgdg.list
msg_ok "Set up PostgreSQL Repository"

msg_info "Installing Node.js"
$STD apt-get update
$STD apt-get install -y nodejs
$STD npm install -g yarn
msg_ok "Installed Node.js"

msg_info "Install/Set up PostgreSQL Database"
$STD apt-get install -y postgresql-16
$STD sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD 'postgres';"
$STD sudo -u postgres psql -c "CREATE DATABASE \"default\";" -c "CREATE DATABASE test;"
msg_ok "Set up PostgreSQL"

msg_info "Setup Twenty"
LOCAL_IP="$(hostname -I | awk '{print $1}')"
APP_SECRET=$(openssl rand -hex 32)
temp_file=$(mktemp)
cd /opt
RELEASE=$(curl -s https://api.github.com/repos/twentyhq/twenty/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
wget -q "https://github.com/twentyhq/twenty/archive/refs/tags/v${RELEASE}.tar.gz" -O $temp_file
tar zxf $temp_file
mv twenty-${RELEASE} /opt/twenty
cd /opt/twenty
cat <<EOF >/opt/twenty/packages/twenty-front/.env
PGHOST='localhost'
REACT_APP_SERVER_BASE_URL=http://${LOCAL_IP}:3000
GENERATE_SOURCEMAP=false
TRANSLATION_IO_API_KEY=xxx
# REACT_APP_PORT=3001
# CHROMATIC_PROJECT_TOKEN=
VITE_DISABLE_TYPESCRIPT_CHECKER=true
VITE_DISABLE_ESLINT_CHECKER=true
# VITE_ENABLE_SSL=false
# VITE_HOST=localhost.com
# SSL_KEY_PATH="./certs/your-cert.key"
# SSL_CERT_PATH="./certs/your-cert.crt"
EOF
cat <<EOF >/opt/twenty/packages/twenty-server/.env
NODE_ENV=development
PG_DATABASE_URL=postgres://postgres:postgres@localhost:5432/default
REDIS_URL=redis://localhost:6379
APP_SECRET=${APP_SECRET}
SIGN_IN_PREFILLED=true
FRONTEND_URL=http://localhost:3001
EOF
sed -i '366s/twenty-front/twenty-front --host/g' /opt/twenty/package.json
$STD yarn
$STD npx nx database:reset twenty-server
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "Setup Twenty"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/twenty.service
[Unit]
Description=Twenty Service
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/twenty
ExecStart=/usr/bin/npx nx start
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now twenty
msg_ok "Created Service"

motd_ssh
customize

msg_info "Cleaning up"
rm -rf $temp_file
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
