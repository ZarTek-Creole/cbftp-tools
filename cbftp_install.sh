#!/bin/bash

###############################################################################################
#   Name         : cbftp-tools
#
#   Filename     : cbftp_install.sh
#
#   Description  :
#       This Bash script allows you to download cbftp and install it within the
#       operating system (/usr/share/cbftp).
#
#   Usage        :
#       sudo ./cbftp_install.sh [-h] [-i] [-u] [-r] [-U]
#
#   Options      :
#       -h, --help        Show this help screen.
#       -i, --install     Install cbftp.
#       -u, --uninstall   Uninstall cbftp.
#       -r, --reinstall   Reinstall cbftp.
#       -U, --update      Update cbftp.
#
#   Donations    :
#       https://github.com/ZarTek-Creole/DONATE
#
#   Author       :
#       ZarTek @ https://github.com/ZarTek-Creole
#
#   Repository   :
#       https://github.com/ZarTek-Creole/cbftp
#
#   Support      :
#       https://github.com/ZarTek-Creole/cbftp/issues
#
#   Acknowledgements :
#       Special thanks to the cbftp project, PCFiL, harrox, deeps, and all developers in the scene.
#       Special thanks to all the contributors and users of cbftp-updater for their support
#       and contributions to the project.
###############################################################################################

set -Eeuo pipefail
export LANG=en_US

trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR
CB_SVN="https://cbftp.glftpd.io/svn/cbftp"
CB_DIR_SRC="/usr/local/src/cbftp"
CB_BINARY_DEST="/usr/local/bin/cbftp" 

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

check_dependencies() {
    local dependencies=(svn)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo "Error: ${cmd} is required but not installed. Install it with 'sudo apt-get install subversion'."
            exit 1
        fi
    done
}

install_cbftp() {
    if [ -e "${CB_BINARY_DEST}" ]; then
        echo "cbftp is already installed in ${CB_BINARY_DEST}."
        exit 1
    fi
    echo "Downloading cbftp..."
    svn co ${CB_SVN} ${CB_DIR_SRC} | grep revision || {
        echo "Error: Failed to download cbftp."
        exit 1
    }
    echo "cbftp downloaded."
    build_cbftp
    deploy_cbftp
    make_clean
    echo "cbftp installed."
}

build_cbftp() {
    mkdir -p "${CB_DIR_SRC}/"
    cd "${CB_DIR_SRC}" || { echo "Failed to change to directory ${CB_DIR_SRC}"; exit 1; }
    echo "Building cbftp..."
    make -j"$(nproc)" -s || { echo "Build failed"; exit 1; }

    cd - > /dev/null
}

make_clean() {
    cd "${CB_DIR_SRC}" || { echo "Failed to change to directory ${CB_DIR_SRC}"; exit 1; }
    echo "Cleaning cbftp..."
    make clean -s > /dev/null 2>&1 || { echo "Clean failed"; exit 1; }
    echo "cbftp cleaned."
    cd - > /dev/null
}

deploy_cbftp() {
    echo "Deploying new cbftp binary..."
    install -m 755 "${CB_DIR_SRC}/bin/cbftp" "${CB_BINARY_DEST}" || { echo "Failed to deploy cbftp"; exit 1; }
    echo "cbftp deployed."
}

uninstall_cbftp() {
    if [ -d "${CB_DIR_SRC}" ]; then
        echo "Removing cbftp..."
        rm -rf ${CB_DIR_SRC} || {
            echo "Error: Failed to uninstall cbftp."
            exit 1
        }
        echo "cbftp removed."
    else
        echo "cbftp is not installed in ${CB_DIR_SRC}."
    fi

    if [ -f "${CB_BINARY_DEST}" ]; then
        echo "Removing ${CB_BINARY_DEST}..."
        unlink ${CB_BINARY_DEST} || {
            echo "Error: Failed to remove ${CB_BINARY_DEST}."
            exit 1
        }
        echo "${CB_BINARY_DEST} removed."
    else
        echo "${CB_BINARY_DEST} is not present."
    fi
}

reinstall_cbftp() {
    uninstall_cbftp
    install_cbftp
}

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help        Show this help screen."
    echo "  -i, --install     Install cbftp."
    echo "  -u, --uninstall   Uninstall cbftp."
    echo "  -r, --reinstall   Reinstall cbftp."
    echo "  -U, --update      Update cbftp."
    exit 0
}

function core() {
    # Display menu when no arguments are provided
    if [ $# -eq 0 ]; then
        PS3="Please select an option: "
        options=("Install cbftp" "Uninstall cbftp" "Reinstall" "Update cbftp" "Commandline help" "Exit")
        REPLY=
        # shellcheck disable=SC2034
        select option in "${options[@]}"; do
            case ${REPLY} in
                1)
                    install_cbftp
                    break
                ;;
                2)
                    uninstall_cbftp
                    break
                ;;
                3)
                    reinstall_cbftp
                    break
                ;;
                4)
                    /usr/local/bin/cbftp-update
                    break
                ;;
                5)
                    show_help
                ;;
                6)
                    exit 0
                ;;
                *)
                    echo "Invalid option. Please choose a valid option."
                ;;
            esac
        done
    else
        # Parse command line options
        OPTIONS=$(getopt -o hiurU --long help,install,uninstall,reinstall,update -n "$0" -- "$@")
        # shellcheck disable=SC2181
        if [ $? -ne 0 ]; then
            echo "Error in getopt" >&2
            exit 1
        fi
        eval set -- "${OPTIONS}"

        while true; do
            case "$1" in
                -h|--help)
                    show_help
                ;;
                -i|--install)
                    install_cbftp
                ;;
                -u|--uninstall)
                    uninstall_cbftp
                ;;
                -r|--reinstall)
                    reinstall_cbftp
                ;;
                -U|--update)
                    /usr/local/bin/cbftp-update
                ;;
                --)
                    shift
                    break
                ;;
                *)
                    echo "Invalid option: $1"
                    exit 1
                ;;
            esac
            shift
        done
        shift $((OPTIND-1))
    fi
}

function main() {
    check_root
    check_dependencies
    core "$@"
}
main "$@"
exit 0
