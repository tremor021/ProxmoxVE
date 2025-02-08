#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tremor021/ProxmoxVE/refs/heads/astroluma/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Sanjeet990/Astroluma

# App Default Values
APP="Astroluma"
var_tags="dashboard"
var_cpu="2"
var_ram="2048"
var_disk="8"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
base_settings

variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/astroluma ]]; then msg_error "No ${APP} Installation Found!"; exit; fi
        msg_info "Updating $APP"
        systemctl stop astroluma
        RELEASE=$(curl -s https://api.github.com/repos/Sanjeet990/Astroluma/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
        wget -q "https://github.com/YuukanOO/seelf/archive/refs/tags/v${RELEASE}.tar.gz"
        tar -xzf v${RELEASE}.tar.gz
        rm -rf /opt/astroluma
        mv -f Astroluma-${RELEASE} /opt/astroluma
        cd /opt/astroluma
        npm install
        cd client
        npm run build
        systemctl enable -q --now astroluma
        msg_ok "Updated $APP"
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"