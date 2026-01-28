#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://vikunja.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt install -y make
msg_ok "Installed Dependencies"

fetch_and_deploy_gh_release "vikunja" "go-vikunja/vikunja" "binary"

msg_info "Configuring Vikunja"
sed -i 's|^# \(service:\)|\1|' /etc/vikunja/config.yml
sed -i 's|^# \(database:\)|\1|' /etc/vikunja/config.yml
sed -i 's|^# \(files:\)|\1|' /etc/vikunja/config.yml
sed -i "s|^  # \(publicurl: \).*|  \1\"http://$LOCAL_IP\"|" /etc/vikunja/config.yml
sed -i '0,/^  # \(timezone: \).*/s//  \1Etc\/UTC/' /etc/vikunja/config.yml
sed -i 's|^  # \(path: "/etc/vikunja/vikunja.db"\)|  \1|' /etc/vikunja/config.yml
sed -i 's|^  # \(basepath: \).*|  \1/etc/vikunja/files|' /etc/vikunja/config.yml
systemctl start vikunja
msg_ok "Configured Vikunja"

motd_ssh
customize
cleanup_lxc
