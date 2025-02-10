#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/tremor021/ProxmoxVE/refs/heads/codexdocs/misc/build.func)
# Copyright (c) 2021-2025 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]

APP="CodeX Docs"
TAGS="documentation"
var_cpu="1"
var_ram="512"
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

    if [[ ! -d /opt/codexdocs ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    RELEASE=$(curl -s https://api.github.com/repos/codex-team/codex.docs/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    if [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        msg_info "Updating $APP"

        msg_info "Stopping $APP"
        systemctl stop codexdocs
        msg_ok "Stopped $APP"

        msg_info "Updating $APP to v${RELEASE}"
        wget -q "https://github.com/codex-team/codex.docs/archive/refs/tags/v${RELEASE}.tar.gz"
        tar zxf v${RELEASE}.tar.gz
        mv codex.docs-${RELEASE}/ /opt/codexdocs
        cd /opt/codexdocs
        touch docs-config.local.yaml
        yarn install &> /dev/null
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