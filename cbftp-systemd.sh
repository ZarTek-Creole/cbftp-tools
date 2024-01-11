#!/bin/bash
###############################################################################################
#   Name         : cbftp-tools
#
#   Filename     : cbftp-systemd.sh
#
#   Description  :
#       This Bash script facilitates the installation of the cbftp service in systemd,
#       enabling manipulation through 'systemctl <cmd> cbftp' commands
#
#   Usage        :
#       sudo ./cbftp-systemd [-h] [-i [username]] [-u [username]] [status|restart|start|stop|join [username]]
#
#   Options      :
#       -h, --help                 Show help"
#       -i, --install   [username] Install the CBFTP service (default: root)"
#       -u, --uninstall [username] Uninstall the CBFTP service (default: root)"
#       status          [username] Show status of the CBFTP service
#       restart         [username] Restart the CBFTP service
#       start           [username] Start the CBFTP service
#       stop            [username] Stop the CBFTP service
#       join            [username] Join the screen
#
#   Donations    :
#       https://github.com/ZarTek-Creole/DONATE
#
#   Author       :
#       ZarTek @ https://github.com/ZarTek-Creole
#
#   Repository   :
#       https://github.com/ZarTek-Creole/cbftp-tools
#
#   Support      :
#       https://github.com/ZarTek-Creole/cbftp-tools/issues
#
#   Acknowledgements :
#       Special thanks to the cbftp project, PCFiL, harrox, deeps, and all developers in the scene.
#       Special thanks to all the contributors and users of cbftp-updater for their support
#       and contributions to the project.
#
###############################################################################################

set -Eeuo pipefail
export LANG=en_US

CB_DIR_DEST="/usr/local/bin"  

# Error handling trap
trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

# Check if the script is running as root
check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

# Check for required dependencies
check_dependencies() {
    local dependencies=("svn" "make" "screen" "systemctl")
    for cmd in "${dependencies[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo "Error: '${cmd}' is required but not installed. Install it with 'sudo apt-get install ${cmd}'."
            exit 1
        fi
    done
}

# Configure the CBFTP service
create_file_service() {
    USERNAME="$1"
    CB_SERVICE="$2"
    cat > "/etc/systemd/system/${CB_SERVICE}.service" <<EOF
[Unit]
Description=cbftp ${USERNAME} Service
After=network.target

[Service]
Type=oneshot
WorkingDirectory=${CB_DIR_DEST}
ExecStart=/usr/bin/screen -dmS ${CB_SERVICE} ${CB_DIR_DEST}/cbftp
ExecStop=/usr/bin/screen -S ${CB_SERVICE} -X quit
RemainAfterExit=yes
User=${USERNAME}
Group=${USERNAME}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}

# Function to show help
show_help() {
    echo "Usage: $0 [-h] [-i [username]] [-u [username]] [status|restart|start|stop [username]]"
    echo "Options:"
    echo "  -h, --help                 Show help"
    echo "  -i, --install   [username] Install the CBFTP service"
    echo "  -u, --uninstall [username] Uninstall the CBFTP service"
    echo "  status          [username] Show status of the CBFTP service"
    echo "  restart         [username] Restart the CBFTP service"
    echo "  start           [username] Start the CBFTP service"
    echo "  stop            [username] Stop the CBFTP service"
    echo "  join            [username] Join the screen"
    exit 0
}

# Function to install the CBFTP service
install_cbftp_service() {
    local USERNAME="${1:-root}"
        if ! check_user_exists "$USERNAME" || ! check_group_exists "$USERNAME"; then
            echo "User or group $USERNAME does not exist."
            exit 1
        fi

    echo "Installing CBFTP service for '${USERNAME}'..."
    CB_SERVICE="cbftp_${USERNAME}"
    create_file_service "${USERNAME}" "${CB_SERVICE}"
    
    # Reload systemd configuration
    systemctl daemon-reload
    
    # Enable and start the CBFTP service
    systemctl enable "${CB_SERVICE}"
    systemctl start "${CB_SERVICE}"
    exit 0
}

# Function to uninstall the CBFTP service
uninstall_cbftp_service() {
    local USERNAME="${1:-root}"
    echo "Uninstalling CBFTP service for '${USERNAME}'..."
    CB_SERVICE="cbftp_${USERNAME}"
    if [ ! -f "/etc/systemd/system/${CB_SERVICE}.service" ]; then
        echo "Error: ${CB_SERVICE} service not found. Please check if it is installed."
        exit 1
    fi
    systemctl stop "${CB_SERVICE}"
    systemctl disable "${CB_SERVICE}"
    rm "/etc/systemd/system/${CB_SERVICE}.service"
    exit 0
}

show_status() {
    local USERNAME="${1:-root}"
    CB_SERVICE="cbftp_${USERNAME}"

    if [ ! -f "/etc/systemd/system/${CB_SERVICE}.service" ]; then
        echo "Error: ${CB_SERVICE} service not found. Please check if it is installed."
        exit 1
    fi
    if ! su - "${USERNAME}" -c "/usr/bin/screen -list | grep -q \"${CB_SERVICE}\""; then
        echo "${CB_SERVICE} is not running."
    else
        echo "${CB_SERVICE} is running."
    fi
    exit 0
}
check_user_exists() {
    if id "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

check_group_exists() {
    if getent group "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}
join_cbftp_service() {
    local USERNAME="${1:-root}"
    CB_SERVICE="cbftp_${USERNAME}"
    if [ ! -f "/etc/systemd/system/${CB_SERVICE}.service" ]; then
        echo "Error: ${CB_SERVICE} service not found. Please check if it is installed."
        exit 1
    fi
    su -  "${USERNAME}" -c "/usr/bin/screen -r "${CB_SERVICE}""
    exit 0
}
stop_cbftp_service() {
    local USERNAME="${1:-root}"
    CB_SERVICE="cbftp_${USERNAME}"
    if [ ! -f "/etc/systemd/system/${CB_SERVICE}.service" ]; then
        echo "Error: ${CB_SERVICE} service not found. Please check if it is installed."
        exit 1
    fi
    systemctl stop "${CB_SERVICE}" || { echo "Failed to stop service ${CB_SERVICE}"; exit 1; }
    echo "${CB_SERVICE} service stopped successfully."
    exit 0
}
start_cbftp_service() {
    local USERNAME="${1:-root}"
    CB_SERVICE="cbftp_${USERNAME}"
    if [ ! -f "/etc/systemd/system/${CB_SERVICE}.service" ]; then
        echo "Error: ${CB_SERVICE} service not found. Please check if it is installed."
        exit 1
    fi
    systemctl start "${CB_SERVICE}" || { echo "Failed to start service ${CB_SERVICE}"; exit 1; }
    echo "${CB_SERVICE} service started successfully."
    exit 0
}
restart_cbftp_service() {
    local USERNAME="${1:-root}"
    CB_SERVICE="cbftp_${USERNAME}"
    if [ ! -f "/etc/systemd/system/${CB_SERVICE}.service" ]; then
        echo "Error: ${CB_SERVICE} service not found. Please check if it is installed."
        exit 1
    fi
    systemctl restart "${CB_SERVICE}" || { echo "Failed to restart service ${CB_SERVICE}"; exit 1; }
    echo "${CB_SERVICE} service restarted successfully."
    exit 0
}
function core() {
    if [ $# -eq 0 ]; then
        PS3="Please select an option: "
        options=("Install CBFTP service" "Uninstall CBFTP service" "Show Status" "Restart Service" "Start Service" "Stop Service" "Join the screen" "Help" "Quit")
        # shellcheck disable=SC2034
        select option in "${options[@]}"; do
            case ${REPLY} in
                1)
                    read -r -p "Enter a username (default: root): " USERNAME
                    USERNAME="${CB_USER:-root}"
                    install_cbftp_service "${USERNAME}"
                    break
                ;;
                2)
                    read -r -p "Enter a username (default: root): " USERNAME
                    uninstall_cbftp_service "${USERNAME}"
                    break
                ;;
                3)
                    read -r -p "Enter a username (default: root): " USERNAME
                    show_status "${USERNAME}"
                    break
                ;;
                4)
                    read -r -p "Enter a username (default: root): " USERNAME
                    restart_cbftp_service "${USERNAME}"
                    break
                ;;
                5)
                    read -r -p "Enter a username (default: root): " USERNAME
                    start_cbftp_service "${USERNAME}"
                    break
                ;;
                6)
                    read -r -p "Enter a username (default: root): " USERNAME
                    stop_cbftp_service "${USERNAME}"
                    break
                ;;
                7)
                    read -r -p "Enter a username (default: root): " USERNAME
                    join_cbftp_service "${USERNAME}"
                    break
                ;;
                8)
                    show_help
                ;;
                9)
                    exit 0
                ;;
                *)
                    echo "Invalid option. Please choose a valid option."
                ;;
            esac
        done
    else
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    show_help
                    break
                ;;
                -i|--install)
                    install_cbftp_service "$2"
                    shift
                    break
                ;;
                -u|--uninstall)
                    uninstall_cbftp_service "$2"
                    shift
                    break
                ;;
                status|restart|start|stop|join)
                    USERNAME="${2:-root}"
                    case "$1" in
                        status)
                            show_status "${USERNAME}"
                            break
                        ;;
                        restart)
                            restart_cbftp_service "${USERNAME}"
                            break
                        ;;
                        start)
                            start_cbftp_service "${USERNAME}"
                            break
                        ;;
                        stop)
                            stop_cbftp_service "${USERNAME}"
                            break
                        ;;
                        join)
                            join_cbftp_service "${USERNAME}"
                            break
                        ;;
                    esac
                    shift
                    break
                ;;
                *)
                    echo "Invalid option: $1"
                    show_help
                ;;
            esac
            shift
        done
    fi
    exit 0
}


# Main function
main() {
    check_root
    check_dependencies
    core "$@"
}

main "$@"
