#!/bin/bash

###############################################################################################
#
#   Name         :
#       cbftp-updater.sh
#
#   Description  :
#       Bash script for managing and automatically updating cbftp via Subversion (SVN).
#       Simplify the task of keeping your cbftp installation up to date with this efficient script.
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
#
#   Acknowledgements :
#       Special thanks to the cbftp project, PCFiL, harrox, deeps, and all developers in the scene. 
#       Special thanks to all the contributors and users of cbftp-updater for their support 
#       and contributions to the project.
###############################################################################################

set -Eeuo pipefail

# Configuration
CBUSER=my_user # The user under which cbftp is executed
CBSERVICE=cbftp.service # Service name, if you are using a systemctl service
CBSCREEN=cbftp # Screen name, if you are not using a systemctl service
CBDIRSRC="/path/to/source/directory" # Directory where the cbftp source is located
CBDIRDEST="/path/to/destination/directory" # Directory where the cbftp binary will be placed
SVN_URL="https://cbftp.glftpd.io/svn" # without the /cbftp ending

trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

check_dependencies() {
    local dependencies=(svn make screen)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is required but not installed. Install it with 'sudo apt-get install subversion build-essential screen'."
            exit 1
        fi
    done
}

verify_directory() {
    if [ ! -d "$1" ]; then
        echo "The directory $1 does not exist. Please check the path and try again."
        exit 1
    fi
}

get_svn_info() {
    svn info "$1" --show-item "$2"
}

update_sources() {
    svn update
}

build_cbftp() {
    echo "Changing to directory: $CBDIRSRC"
    cd "$CBDIRSRC" || { echo "Failed to change to directory $CBDIRSRC"; exit 1; }

    echo "Building cbftp..."
    make -j$(nproc) -s || { echo "Build failed"; exit 1; }

    cd - > /dev/null
}

has_systemctl() {
    if command -v systemctl &> /dev/null; then
        if ps --no-headers -o comm 1 | grep -q systemd; then
            return 0
        fi
    fi
    return 1
}

stop_cbftp_service() {
    if has_systemctl; then
        echo "Using systemctl to stop the service."
        systemctl stop "$CBSERVICE" || { echo "Failed to stop service $CBSERVICE"; exit 1; }
    else
        local pids=$(pgrep -f /cbftp$)
        for pid in $pids; do
            if [ -n "$pid" ]; then
                echo "Killing cbftp process with PID $pid"
                kill "$pid" || { echo "Failed to kill cbftp process with PID $pid"; exit 1; }
            fi
        done
        sleep 2  # Wait for the process to stop
        local pids_after_kill=$(pgrep -f /cbftp$)
        if [ -n "$pids_after_kill" ]; then
            echo "Forcing kill for remaining cbftp processes"
            kill -9 $pids_after_kill
        fi
    fi
}

start_cbftp_service() {
    if has_systemctl; then
        systemctl start "$CBSERVICE" || { echo "Failed to start service $CBSERVICE"; exit 1; }
    else
        /usr/bin/screen -dmS "$CBSCREEN" "${CBDIRDEST}/cbftp"
    fi
}

deploy_cbftp() {
    echo "Stopping cbftp service..."
    stop_cbftp_service

    echo "Deploying new cbftp binary..."
    cp -v "$CBDIRSRC/bin/cbftp" "$CBDIRDEST" || { echo "Failed to deploy cbftp"; exit 1; }
    chown -R "$CBUSER:$CBUSER" "$CBDIRDEST"
    chmod +x "$CBDIRDEST/cbftp"

    echo "Starting cbftp service..."
    start_cbftp_service
}

restart_service() {
    systemctl stop "$CBSERVICE" && systemctl start "$CBSERVICE"
}

initialize_or_update_svn() {
    if [ ! -d "$CBDIRSRC/.svn" ]; then
        echo "Initializing SVN repository in $CBDIRSRC"
        svn checkout -q "${SVN_URL}/cbftp" "$CBDIRSRC" || exit 1
        NEEDS_BUILD=1
    else
        local current_url=$(get_svn_info "$CBDIRSRC" repos-root-url)
        if [ "$current_url" != "${SVN_URL}/cbftp" ]; then
            echo "Updating SVN repository URL. Changing from $current_url to ${SVN_URL}/cbftp"
            svn relocate "${SVN_URL}/cbftp" "$CBDIRSRC" || exit 1
        fi
    fi
}

main() {
    echo "Starting cbftp update."
    check_root
    check_dependencies
    NEEDS_BUILD=0
    initialize_or_update_svn
    verify_directory "$CBDIRSRC"

    local local_rev=$(get_svn_info "$CBDIRSRC" last-changed-revision)
    local remote_rev=$(get_svn_info "$CBDIRSRC" revision)

    if [ "$local_rev" == "$remote_rev" ] && [ "$NEEDS_BUILD" -eq 0 ]; then
        echo "Latest version of cbftp already installed (revision: $local_rev)."
        exit 0
    fi

    echo "Updating cbftp from revision $local_rev to $remote_rev."
    [ "$NEEDS_BUILD" -eq 1 ] || update_sources
    build_cbftp
    deploy_cbftp
    restart_service
    echo "cbftp update completed successfully."
}

main "$@"
