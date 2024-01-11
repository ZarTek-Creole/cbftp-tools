#!/bin/bash

###############################################################################################
#   Name         : cbftp-tools
#
#   Filename     : cbftp-init.d.sh
#
#   Description  :
#       This Bash script facilitates the installation of the cbftp service in init.d,
#       enabling manipulation through 'services cbftp <cmd>' commands.
#
#   Usage        :
#       sudo ./cbftp-init.d.sh [--help] [--install [username]] [--uninstall [username]] [status|restart|start|stop|join [username]]
#
#   Options      :
#       --help                      Show this help.
#       --install       [username] Install the CBFTP service (default: root).
#       --uninstall     [username] Uninstall the CBFTP service (default: root).
#       status          [username]  Show the status of the CBFTP service.
#       restart         [username]  Restart the CBFTP service.
#       start           [username]  Start the CBFTP service.
#       stop            [username]  Stop the CBFTP service.
#       join            [username]  Join the screen.
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
###############################################################################################

set -Eeuo pipefail
export LANG=en_US

INIT_SCRIPT_PATH="/etc/init.d/cbftp"
trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

# Function to show help
show_help() {
    echo "Usage: $0 [--help] [--install [username]] [--uninstall [username]] [status|restart|start|stop [username]]"
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

# Configure the CBFTP service
create_file_service() {
    USERNAME="${1:-root}"
    CB_INIT_SCRIPT="${2:-cbftp_${USERNAME}}"
    INIT_SCRIPT_PATH="${3:-/etc/init.d/cbftp_${USERNAME}}"

    cat > "${INIT_SCRIPT_PATH}" <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides:          cbftp
# Required-Start:   \$remote_fs \$syslog
# Required-Stop:    \$remote_fs \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: cbftp init script
# Description:       Start, stop, join, update, and check the status of the cbftp service
### END INIT INFO

case \$1 in
    start)
        if ! su - "${USERNAME}" -c "/usr/bin/screen -list | grep -q \"${CB_INIT_SCRIPT}\""; then
            su - "${USERNAME}" -c "/usr/bin/screen -dmS '${CB_INIT_SCRIPT}' '/usr/local/bin/cbftp'"
            echo "cbftp started."
        else
            echo "cbftp is already running."
        fi
        ;;
    restart)
        su -  "${USERNAME}" -c "/usr/bin/screen -S "${CB_INIT_SCRIPT}" -X quit"
        su -  "${USERNAME}" -c "/usr/bin/screen -dmS "${CB_INIT_SCRIPT}" "/usr/local/bin/cbftp""
        echo "cbftp restarted."
        ;;
    stop)
        su -  "${USERNAME}" -c "/usr/bin/screen -S "${CB_INIT_SCRIPT}" -X quit"
        ;;
    join)
        su -  "${USERNAME}" -c "/usr/bin/screen -r "${CB_INIT_SCRIPT}""
        ;;
    update)
        su -  "${USERNAME}" -c "/usr/bin/screen -S "${CB_INIT_SCRIPT}" -X quit"
        /usr/share/cbftp-tools/cbftp-update.sh
        su -  "${USERNAME}" -c "/usr/bin/screen -dmS "\${CB_INIT_SCRIPT}" \"/usr/local/bin/cbftp\""
        ;;
    status)
        if su - "${USERNAME}" -c "/usr/bin/screen -list | grep -q "${CB_INIT_SCRIPT}""; then
            echo "cbftp is running."
        else
            echo "cbftp is not running."
        fi
        ;;
    *)
        echo "Usage:  \$0 {start|stop|join|update|status}"
        exit 1
        ;;
esac

exit 0
EOF
}

# Functions for actions
install_init_script() {
    local USERNAME="${2:-root}"
    local CB_INIT_SCRIPT="cbftp_${USERNAME}"
    echo "Installing the ${CB_INIT_SCRIPT} script..."
    INIT_SCRIPT_PATH="/etc/init.d/${CB_INIT_SCRIPT}"
    create_file_service "${USERNAME}" "${CB_INIT_SCRIPT}" "${INIT_SCRIPT_PATH}"
    sudo chmod +x "${INIT_SCRIPT_PATH}"
    echo "Configuring the initialization script..."
    sudo update-rc.d "${CB_INIT_SCRIPT}" defaults
    # Give execute permissions to the file
    echo "Starting the ${CB_INIT_SCRIPT} service..."
    sudo "${INIT_SCRIPT_PATH}" start
    echo "The initialization script for cbftp has been created successfully at location: ${INIT_SCRIPT_PATH}"
    echo "The initialization script has been installed successfully."
    echo "You can now use the script with the following commands:"
    echo "  sudo service ${CB_INIT_SCRIPT} restart"
    echo "  sudo service ${CB_INIT_SCRIPT} start"
    echo "  sudo service ${CB_INIT_SCRIPT} stop"
    echo "  sudo service ${CB_INIT_SCRIPT} join"
    echo "  sudo service ${CB_INIT_SCRIPT} status"
    echo "  sudo service ${CB_INIT_SCRIPT} update"
}

uninstall_init_script() {
    local USERNAME="${1:-root}"
    local CB_INIT_SCRIPT="cbftp_${USERNAME}"
    INIT_SCRIPT_PATH="/etc/init.d/${CB_INIT_SCRIPT}"
    if [ -f "${INIT_SCRIPT_PATH}" ]; then
        echo "Stopping the ${CB_INIT_SCRIPT} init..."
        sudo "${INIT_SCRIPT_PATH}" stop
        echo "Disabling the initialization script..."
        sudo update-rc.d -f "${CB_INIT_SCRIPT}" remove
        echo "Uninstalling the initialization script..."
        sudo rm -f "${INIT_SCRIPT_PATH}"
        echo "The initialization script ${CB_INIT_SCRIPT} has been uninstalled successfully."
    else
        echo "The initialization script ${CB_INIT_SCRIPT} is already uninstalled."
    fi
}

function core() {

    # Display a menu when no arguments are provided
    if [ $# -eq 0 ]; then
        PS3="Please select an option: "
        options=("Install init.d" "Uninstall init.d" "Command-line help" "Exit")
        REPLY=
        # shellcheck disable=SC2034
        select option in "${options[@]}"; do
            case ${REPLY} in
                1)
                    read -r -p "Enter a username (default: root): " USERNAME
                    install_init_script "${USERNAME}"
                    break
                ;;
                2)
                    read -r -p "Enter a username (default: root): " USERNAME
                    uninstall_init_script "${USERNAME}"
                    break
                ;;
                3)
                    show_help
                ;;
                4)
                    exit 0
                ;;
                *)
                    echo "Invalid option. Please choose a valid option."
                    show_help
                ;;
            esac
        done
    else
        # Parse command line options
        OPTIONS=$(getopt -o hiu --long help,install,uninstall -n "$0" -- "$@")
        # shellcheck disable=SC2181
        if [ $? -ne 0 ]; then
            echo "Error in getopt" >&2
            show_help
            exit 1
        fi
        eval set -- "${OPTIONS}"
        
        while true; do
            case "$1" in
                -h|--help)
                    show_help
                ;;
                -i|--install)
                    shift
                    install_init_script "$@"
                    break
                ;;
                -u|--uninstall)
                    shift
                    shift
                    uninstall_init_script "$@"
                    break
                ;;
                --)
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
        shift $((OPTIND-1))
    fi
}


main() {
    check_root
    core "$@"
}

main "$@"
exit 0
