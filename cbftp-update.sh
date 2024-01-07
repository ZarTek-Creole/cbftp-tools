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
export LANG=en_US
SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"

CFG_FILE="$SCRIPT_DIR/cbftp-configuration.cfg"

if [ ! -f "$CFG_FILE" ]; then
    echo "Error: Configuration file 'cbftp-configuration.cfg' not found. Please rename 'cbftp-configuration.cfg.default' to 'cbftp-configuration.cfg' and edit it with your configuration."
    exit 1
fi

# Load configuration using "source" for better readability
# shellcheck disable=SC1090
. "$CFG_FILE" || {
    echo "Error: Failed to load configuration from '$CFG_FILE'. Please check the file for errors."
    exit 1
}


trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

check_dependencies() {
    local dependencies=(svn make screen curl xmllint)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: $cmd is required but not installed. Install it with 'sudo apt-get install subversion build-essential screen libxml2-utils curl'."
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

get_svn_info2() {
    svn info "$1" --show-item "$2"
}

update_sources() {
    cd "$CB_DIR_SRC" || { echo "Failed to change to directory $CB_DIR_SRC"; exit 1; }
    svn update
}

build_cbftp() {
    echo "Changing to directory: $CB_DIR_SRC"
    cd "$CB_DIR_SRC" || { echo "Failed to change to directory $CB_DIR_SRC"; exit 1; }
    echo "Building cbftp..."
    make -j"$(nproc)" -s || { echo "Build failed"; exit 1; }
    
    cd - > /dev/null
}

# Function to fetch specific HTML content and remove specified tags
fetch_and_clean_html() {
    local url=$1
    local xpath_expression=$2
    local tags_to_remove=$3

    # Fetch HTML content
    local html_content=$(curl -s "$url")

    # Extract specific content using xpath
    local extracted_content=$(echo "$html_content" | xmllint --html --xpath "$xpath_expression" - 2>/dev/null)

    # Remove specified HTML tags
    for tag in $tags_to_remove; do
        extracted_content=$(echo "$extracted_content" | sed "s/<$tag>//g; s/<\/$tag>//g")
    done

    echo "$extracted_content"
}

has_systemctl() {
    if command -v systemctl &> /dev/null; then
        if ps --no-headers -o comm 1 | grep -q systemd; then
            return 0
        fi
    fi
    return 1
}

stop_cbftp_or_service() {
    # Check if systemd service exists and is active
    if has_systemctl && systemctl is-active --quiet "$CB_SERVICE" &> /dev/null; then
        echo "Stopping $CB_SERVICE service..."
        systemctl stop "$CB_SERVICE"
        local stopped
        stopped=$?
        if [ ! "$stopped" -eq 0 ]; then
            echo "Failed to stop $CB_SERVICE service"
            exit 1
        fi
        echo "$CB_SERVICE service stopped successfully."
    else
        # Check if the process $CB_DIR_DEST/cbftp is running
        if pidof -x "$CB_DIR_DEST/cbftp" &> /dev/null; then
            local pid
            pid=$(pidof -x "$CB_DIR_DEST/cbftp")
            echo "Process $CB_DIR_DEST/cbftp is running (PID $pid)."
            echo "Stopping $CB_DIR_DEST/cbftp process..."
            kill -9 "$pid"
            local killed
            killed=$?
            if [ ! "$killed" -eq 0 ]; then
                echo "Failed to stop $CB_DIR_DEST/cbftp process"
                exit 1
            fi
            echo "$CB_DIR_DEST/cbftp process stopped successfully."
        else
            echo "Neither $CB_SERVICE service nor $CB_DIR_DEST/cbftp process is running."
        fi
    fi
}
function show_changelog() {
    # XPath expression for the specific content
    xpath="/html/body/table/tr[11]"

    # HTML tags to be removed
    tags_to_remove="tr td pre"

    # Function call
    cleaned_html=$(fetch_and_clean_html "$CB_WEBSITE" "$xpath" "$tags_to_remove")

    # Display the cleaned HTML content
    echo "$cleaned_html"
}
start_cbftp_service() {
    if has_systemctl && systemctl list-units --all | grep -q "$CB_SERVICE.service"; then
        echo "Starting cbftp service..."
        systemctl start "$CB_SERVICE" || { echo "Failed to start service $CB_SERVICE"; exit 1; }
    else
        echo "Starting cbftp screen..."
        /usr/bin/screen -dmS "$CB_SCREEN" "${CB_DIR_DEST}/cbftp"
    fi
}

deploy_cbftp() {
    echo "Stopping cbftp or cbftp service..."
    stop_cbftp_or_service

    echo "Deploying new cbftp binary..."
    mkdir -p "${CB_DIR_DEST}/"
    cp -v "$CB_DIR_SRC/bin/cbftp" "$CB_DIR_DEST" || { echo "Failed to deploy cbftp"; exit 1; }
    chown -R "$CB_USER:$CB_USER" "$CB_DIR_DEST"
    chmod +x "$CB_DIR_DEST/cbftp"

    start_cbftp_service
}

initialize_or_update_svn() {
    if [ ! -d "$CB_DIR_SRC/.svn" ]; then
        echo "Initializing SVN repository in $CB_DIR_SRC"
        mkdir -p "$CB_DIR_SRC"
        if ! svn checkout -q "${CB_SVN_URL}/cbftp" "$CB_DIR_SRC"; then
            exit 1
        fi
        NEEDS_BUILD=1
    else
        local current_url
        current_url=$(get_svn_info2 "$CB_DIR_SRC" repos-root-url)
        if [ "$current_url" != "${CB_SVN_URL}" ]; then
            echo "Updating SVN repository URL. Changing from $current_url to ${CB_SVN_URL}"
            if ! svn relocate "${CB_SVN_URL}/cbftp" "$CB_DIR_SRC"; then
                exit 1
            fi
        fi
    fi
}
get_svn_info() {
    local dir=$1
    local property=$2
    if [[ "$property" == "last-changed-revision" ]]; then
        svn info "$dir" | grep "Last Changed Rev" | awk '{print $4}'
    elif [[ "$property" == "revision" ]]; then
        svn info "$CB_SVN_URL" | grep "Revision" | awk '{print $2}'
    else
        echo "Propriété inconnue"
    fi
}
main() {
    echo "Starting cbftp update."
    check_root
    check_dependencies
    NEEDS_BUILD=0
    initialize_or_update_svn
    verify_directory "$CB_DIR_SRC"
    cd "$CB_DIR_SRC" || { echo "Failed to change to directory $CB_DIR_SRC"; exit 1; }
    local_rev=$(get_svn_info "$CB_DIR_SRC" last-changed-revision)
    remote_rev=$(get_svn_info "$CB_DIR_SRC" revision)

    
    if [ "$local_rev" == "$remote_rev" ] && [ "$NEEDS_BUILD" -eq 0 ]; then
        echo "Latest version of cbftp already installed (revision: $local_rev)."
        exit 0
    fi
    
    echo "Updating cbftp from revision $local_rev to $remote_rev."
    [ "$NEEDS_BUILD" -eq 1 ] || update_sources
    build_cbftp
    deploy_cbftp
    show_changelog
    echo "cbftp update completed successfully."
}

main "$@"
