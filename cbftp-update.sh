#!/bin/bash

###############################################################################################
#   Name         : cbftp-tools
#
#   Filename     : cbftp-update.sh
#
#   Description  :
#       Bash script for managing and automatically updating cbftp through Subversion (SVN).
#       Simplify the task of keeping your cbftp installation up to date with this efficient script.
#
#   Usage        :
#       sudo ./cbftp-update.sh
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
CB_DIR_SRC="/usr/local/src/cbftp"
CB_SVN_URL="https://cbftp.glftpd.io/svn" # without the /cbftp ending1
CB_BINARY_DEST="/usr/local/bin/cbftp"
CB_WEBSITE="https://cbftp.glftpd.io/"
trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

check_dependencies() {
    local dependencies=(svn make screen curl xmllint)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo "Error: ${cmd} is required but not installed. Install it with 'sudo apt-get install subversion build-essential screen libxml2-utils curl'."
            exit 1
        fi
    done
}

verify_cbftp_directory() {
    if [ ! -d "$1" ]; then
        echo "The directory $1 does not exist. Please check the path and try again."
        exit 1
    fi
}

fetch_svn_info() {
    svn info "$1" --show-item "$2"
}

update_sources() {
    cd "${CB_DIR_SRC}" || { echo "Failed to change to directory ${CB_DIR_SRC}"; exit 1; }
    svn update
}

build_cbftp() {
    echo "Changing to directory: ${CB_DIR_SRC}"
    cd "${CB_DIR_SRC}" || { echo "Failed to change to directory ${CB_DIR_SRC}"; exit 1; }
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
    local html_content
    html_content=$(curl -s "${url}")
    
    # Extract specific content using xpath
    local extracted_content
    extracted_content=$(echo "${html_content}" | xmllint --html --xpath "${xpath_expression}" - 2>/dev/null)
    
    # Remove specified HTML tags
    for tag in ${tags_to_remove}; do
        extracted_content=$(echo "${extracted_content}" | sed "s/<${tag}>//g; s/<\/${tag}>//g")
    done
    
    echo "${extracted_content}"
}

check_systemctl_availability() {
    if command -v systemctl &> /dev/null; then
        # shellcheck disable=SC2009
        if ps --no-headers -o comm 1 | grep -q systemd; then
            return 0
        fi
    fi
    return 1
}

stop_cbftp_or_service() {
    # Check if systemd service exists and is active
    if check_systemctl_availability && [ -d "/etc/systemd/system/" ]; then
        cbftp_services=$(systemctl list-units --all | grep -E 'cbftp' | awk '{print $1}')
        
        for CB_SERVICE in $cbftp_services; do
            echo "Stopping ${CB_SERVICE} service..."
            systemctl stop "${CB_SERVICE}"
            local stopped=$?
            if [ ! "${stopped}" -eq 0 ]; then
                echo "Failed to stop ${CB_SERVICE} service"
            fi
            echo "${CB_SERVICE} service stopped successfully."
        done
    fi
    
    if [ -d "/etc/init.d/" ]; then
        cbftp_init_scripts=$(find /etc/init.d -name 'cbftp*' -type f 2>/dev/null)
        if [ -z "$cbftp_init_scripts" ]; then
            echo "No init.d service starting with cbftp* was found."
        else
            for CB_INIT_SCRIPT in $cbftp_init_scripts; do
                echo "Stopping ${CB_INIT_SCRIPT} service (init.d)..."
                $CB_INIT_SCRIPT stop
                local stopped=$?
                if [ ! "${stopped}" -eq 0 ]; then
                    echo "Failed to stop ${CB_INIT_SCRIPT} service (init.d)"
                    exit 1
                fi
                echo "${CB_INIT_SCRIPT} service stopped successfully (init.d)."
            done
        fi
    fi
}

function show_changelog() {
    # XPath expression for the specific content
    xpath="/html/body/table/tr[11]"
    
    # HTML tags to be removed
    tags_to_remove="tr td pre"
    
    # Function call
    cleaned_html=$(fetch_and_clean_html "${CB_WEBSITE}" "${xpath}" "${tags_to_remove}")
    
    # Display the cleaned HTML content
    echo "${cleaned_html}"
}

start_cbftp_or_service() {
    # Check if systemd service exists and is active
    if check_systemctl_availability && [ -d "/etc/systemd/system/" ]; then
        cbftp_services=$(systemctl list-units --all | grep -E 'cbftp' | awk '{print $1}')
        
        for CB_SERVICE in $cbftp_services; do
            echo "Starting ${CB_SERVICE} service..."
            systemctl start "${CB_SERVICE}"
            local started=$?
            if [ ! "${started}" -eq 0 ]; then
                echo "Failed to start ${CB_SERVICE} service"
            fi
            echo "${CB_SERVICE} service started successfully."
        done
    fi
    
    if [ -d "/etc/init.d/" ]; then
        cbftp_init_scripts=$(find /etc/init.d -name 'cbftp*' -type f 2>/dev/null)
        for CB_INIT_SCRIPT in $cbftp_init_scripts; do
            echo "Starting ${CB_INIT_SCRIPT} service (init.d)..."
            $CB_INIT_SCRIPT start
            local started=$?
            if [ ! "${started}" -eq 0 ]; then
                echo "Failed to start ${CB_INIT_SCRIPT} service (init.d)"
                exit 1
            fi
            echo "${CB_INIT_SCRIPT} service started successfully (init.d)."
        done
    fi
}


deploy_cbftp() {
    echo "Stopping cbftp or cbftp service..."
    stop_cbftp_or_service
    
    echo "Deploying new cbftp binary..."
    install -m 755 "${CB_DIR_SRC}/bin/cbftp" "${CB_BINARY_DEST}" || { echo "Failed to deploy cbftp"; exit 1; }
    echo "cbftp deployed."
    
    start_cbftp_or_service
}

initialize_or_sync_svn() {
    if [ ! -d "${CB_DIR_SRC}/.svn" ]; then
        echo "Initializing SVN repository in ${CB_DIR_SRC}"
        mkdir -p "${CB_DIR_SRC}"
        if ! svn checkout -q "${CB_SVN_URL}/cbftp" "${CB_DIR_SRC}"; then
            exit 1
        fi
        NEEDS_BUILD=1
    else
        local current_url
        current_url=$(fetch_svn_info "${CB_DIR_SRC}" repos-root-url)
        if [ "$current_url" != "${CB_SVN_URL}" ]; then
            echo "Updating SVN repository URL. Changing from $current_url to ${CB_SVN_URL}"
            if ! svn relocate "${CB_SVN_URL}/cbftp" "${CB_DIR_SRC}"; then
                exit 1
            fi
        fi
    fi
}

fetch_svn_revision_info() {
    local dir=$1
    local property=$2
    if [[ "${property}" == "last-changed-revision" ]]; then
        svn info "$dir" | grep "Last Changed Rev" | awk '{print $4}'
        elif [[ "${property}" == "revision" ]]; then
        svn info "${CB_SVN_URL}" | grep "Revision" | awk '{print $2}'
    else
        echo "Unknown property"
    fi
}

main() {
    echo "Starting cbftp update."
    check_root
    check_dependencies
    NEEDS_BUILD=0
    initialize_or_sync_svn
    verify_cbftp_directory "${CB_DIR_SRC}"
    
    local_rev=$(fetch_svn_revision_info "${CB_DIR_SRC}" last-changed-revision)
    remote_rev=$(fetch_svn_revision_info "${CB_DIR_SRC}" revision)
    
    if [ "${local_rev}" == "${remote_rev}" ] && [ "${NEEDS_BUILD}" -eq 0 ]; then
        echo "Latest version of cbftp already installed (revision: ${local_rev})."
        exit 0
    fi
    
    echo "Updating cbftp from revision ${local_rev} to ${remote_rev}."
    [ "${NEEDS_BUILD}" -eq 1 ] || update_sources
    build_cbftp
    deploy_cbftp
    show_changelog
    echo "cbftp update completed successfully."
}

main "$@"
