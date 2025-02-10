#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tremor021/ProxmoxVE/refs/heads/tasmo/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

APP="TasmoCompiler"
TAGS="compiler"
var_cpu="8"
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
    if [[ ! -d /home/tasmota/tasmocompiler ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    RELEASE=$(curl -s https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ ! -f /home/tasmota/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /home/tasmota/${APP}_version.txt)" ]]; then
        msg_info "Stopping $APP"
        systemctl stop tasmocompiler
        msg_ok "Stopped $APP"
        msg_info "Updating $APP to v${RELEASE}"
        su - tasmota
        cd /home/tasmota/tasmocompiler
        git pull
        yarn install
        yarn build
        msg_ok "Updated $APP to v${RELEASE}"
        msg_info "Starting $APP"
        systemctl start tasmocompiler
        msg_ok "Started $APP"
        echo "${RELEASE}" >/home/tasmota/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${RELEASE}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
