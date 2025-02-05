#!/usr/bin/env bash
source <(curl -s hhttps://raw.githubusercontent.com/tremor021/ProxmoxVE/refs/heads/freqtrade/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/freqtrade/freqtrade

APP="Freqtrade"
TAGS="bot"
var_cpu="1"
var_ram="1024"
var_disk="4"
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

    if [[ ! -f [INSTALLATION_CHECK_PATH] ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -fsSL [RELEASE_URL] | [PARSE_RELEASE_COMMAND])
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        msg_info "Stopping $APP"
        systemctl stop [SERVICE_NAME]
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        [UPDATE_COMMANDS]
        msg_ok "Updated $APP to v${RELEASE}"

        msg_info "Starting $APP"
        systemctl start [SERVICE_NAME]
        msg_ok "Started $APP"

        msg_info "Cleaning Up"
        rm -rf [TEMP_FILES]
        msg_ok "Cleanup Completed"

        echo "${RELEASE}" >/opt/${APP}_version.txt
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:[PORT]${CL}"
