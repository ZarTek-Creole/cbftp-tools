#!/bin/bash

###############################################################################################
#
#   Name         :
#       install_service_cb.sh
#
#   Description  :
#       Bash script for automating the installation of cbftp services.
#
#   Donations    :
#       https://github.com/ZarTek-Creole/DONATE
#
#   Author       :
#       ZarTek @ https://github.com/ZarTek-Creole
#
#   Repository   :
#       https://github.com/ZarTek-Creole/cbftp-updater
#
#   Support      :
#       https://github.com/ZarTek-Creole/cbftp-updater/issues
#
#   Acknowledgements :
#       Special thanks to the cbftp project, PCFiL, harrox, deeps, and all developers in the scene.
#       Special thanks to all the contributors and users of cbftp-updater for their support
#       and contributions to the project.
#
###############################################################################################

set -Eeuo pipefail
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

# Configuration file path
CFG_FILE="$SCRIPT_DIR/cbftp-updater.cfg"

# Check if the configuration file exists
if [ ! -f "$CFG_FILE" ]; then
    echo "Error: Configuration file 'cbftp-updater.cfg' not found. Please rename 'cbftp-updater.cfg.default' to 'cbftp-updater.cfg' and edit it with your configuration."
    exit 1
fi

# Load configuration using "source" for better readability
# shellcheck disable=SC1090
. "$CFG_FILE" || {
    echo "Error: Failed to load configuration from '$CFG_FILE'. Please check the file for errors."
    exit 1
}

# Error handling trap
trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

# Check if the script is running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

# Check for required dependencies
check_dependencies() {
    local dependencies=("svn" "make" "screen" "systemctl")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: '$cmd' is required but not installed. Install it with 'sudo apt-get install $cmd'."
            exit 1
        fi
    done
}

# Configure the CBFTP service
configure_service() {
    # Create the cbftp.service file using the template
    cat > "/etc/systemd/system/$CB_SERVICE" <<EOF
[Unit]
Description=CBFTP Service
After=network.target

[Service]
Type=oneshot
WorkingDirectory=$CB_DIR_DEST/cbftp
ExecStart=/usr/bin/screen -dmS $CB_SCREEN $CB_DIR_DEST/cbftp/cbftp
ExecStop=/usr/bin/screen -S $CB_SCREEN -X quit
RemainAfterExit=yes
User=$CB_USER
Group=$CB_USER
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

# Main function
main() {
    check_root
    check_dependencies
    configure_service

    # Reload systemd configuration
    systemctl daemon-reload

    # Enable and start the CBFTP service
    systemctl enable "$CB_SERVICE"
    systemctl start "$CB_SERVICE"
}

main "$@"
