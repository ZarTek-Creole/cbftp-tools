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
CBUSER=my_user
CBSERVICE=cbftp.service
CBDIRSRC="/path/to/source/directory"
CBDIRDEST="/path/to/destination/directory"
SVN_URL="https://cbftp.glftpd.io/svn"

trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

check_dependencies() {
    local dependencies=(svn make systemctl)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is required but not installed. Install it with 'sudo apt-get install subversion build-essential systemctl'."
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
    make
}

deploy_cbftp() {
    cp -v "$CBDIRSRC/bin/cbftp" "$CBDIRDEST"
    chown -R "$CBUSER:$CBUSER" "$CBDIRDEST"
    chmod +x "$CBDIRDEST/cbftp"
}

restart_service() {
    systemctl stop "$CBSERVICE"
    systemctl start "$CBSERVICE"
}

initialize_or_update_svn() {
    if [ ! -d "$CBDIRSRC/.svn" ]; then
        echo "Initializing SVN repository in $CBDIRSRC"
        svn checkout "$SVN_URL" "$CBDIRSRC"
    else
        local current_url=$(get_svn_info "$CBDIRSRC" repos-root-url)
        if [ "$current_url" != "$SVN_URL" ]; then
            echo "Updating SVN repository URL. Changing from $current_url to $SVN_URL"
            svn relocate "$SVN_URL" "$CBDIRSRC"
        fi
    fi
}

main() {
    echo "Starting cbftp update."
    check_root
    check_dependencies
    initialize_or_update_svn
    verify_directory "$CBDIRSRC"

    local local_rev=$(get_svn_info "$CBDIRSRC" last-changed-revision)
    local remote_rev=$(get_svn_info "$CBDIRSRC" revision)

    if [ "$local_rev" == "$remote_rev" ]; then
        echo "Latest version of cbftp already installed (revision: $local_rev)."
        exit 0
    fi

    echo "Updating cbftp from revision $local_rev to $remote_rev."
    update_sources
    build_cbftp
    deploy_cbftp
    restart_service
    echo "cbftp update completed successfully."
}

main "$@"
