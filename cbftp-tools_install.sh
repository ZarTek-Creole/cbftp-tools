#!/bin/bash

###############################################################################################
#   Name         : cbftp-tools
#
#   Filename     : cbftp-tools_install.sh
#
#   Description  :
#       This Bash script allows you to download cbftp-tools and install it within the 
#       operating system (/usr/share/cbftp-tools).
#
#   Usage        :
#       sudo ./cbftp-tools_install.sh [--help] [--install] [--uninstall] [--reinstall] [--update]
#
#       Options  :
#           -h, --help        Show this screen.
#           -i, --install     Install cbftp.
#           -u, --uninstall   Uninstall cbftp.
#           -r, --reinstall   Reinstall cbftp.
#           -U, --update      Update cbftp.
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
CBTOOLS_GIT="https://github.com/ZarTek-Creole/cbftp-tools.git"
CBTOOLS_SRC="/usr/local/src/cbftp-tools"
CBTOOLS_DEST="/usr/local/bin"
BINARY_LIST=("cbftp-update" "cbftp-crontab" "cbftp-init.d" "cbftp_install" "cbftp-systemd" "cbftp-tools_install" "cbftp-tools")

trap 'echo "Error during script execution: $BASH_COMMAND" ; exit 1' ERR

check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

check_dependencies() {
    local dependencies=(git)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "${cmd}" &> /dev/null; then
            echo "Error: ${cmd} is required but not installed. Install it with 'sudo apt-get install ${cmd}'."
            exit 1
        fi
    done
}

install_cbftp_tools() {

    if [ -d "${CBTOOLS_SRC}" ]; then
        echo "cbftp-tools is already installed in ${CBTOOLS_SRC}."
        exit 1
    fi

    download_cbftp_tools
    symbolic_links
    echo "cbftp-tools installed, now run 'cbftp-tools' to use cbftp-tools."

}

download_cbftp_tools() {
    echo "Downloading cbftp-tools..."
    git clone ${CBTOOLS_GIT} ${CBTOOLS_SRC} || {
        echo "Error: Failed to download cbftp-tools."
        exit 1
    }
    echo "cbftp-tools downloaded."
}

symbolic_links() {
    echo "Creating symbolic links..."
    for file in "${BINARY_LIST[@]}"; do
        ln -s "${CBTOOLS_SRC}/${file}.sh" "${CBTOOLS_DEST}/${file}" || { echo "Failed to create symbolic link for ${file}"; exit 1; }
        echo "Symbolic link created for ${file}."
    done
}

remove_symbolic_links() {
    echo "Removing symbolic links..."
    for file in "${BINARY_LIST[@]}"; do
        link="${CBTOOLS_DEST}/${file}"
        if [ -h "${link}" ]; then
            echo "Removing ${link}..."
            unlink "${link}" || {
                echo "Error: Failed to unlink ${link}."
                exit 1
            }
            echo "${link} unlinked."
        else 
            echo "${link} is not present."
        fi
    done
}


uninstall_cbftp_tools() {
    if [ -d "${CBTOOLS_SRC}" ]; then
        echo "Removing cbftp-tools..."
        rm -rf ${CBTOOLS_SRC} || {
            echo "Error: Failed to remove cbftp-tools."
            exit 1
        }
        echo "cbftp-tools removed."
    else 
        echo "cbftp-tools is not installed in ${CBTOOLS_SRC}."
    fi

    remove_symbolic_links
}

reinstall_cbftp_tools() {
    uninstall_cbftp_tools
    install_cbftp_tools
}

# Function to display help
show_help() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -h, --help        Show this screen."
    echo "  -i, --install     Install cbftp."
    echo "  -u, --uninstall   Uninstall cbftp."
    echo "  -r, --reinstall   Reinstall cbftp."
    echo "  -U, --update   Update cbftp."
    exit 0
}

function core() {
    # Display menu when no arguments are provided
    if [ $# -eq 0 ]; then
        PS3="Please select an option: "
        options=("Install cbftp" "Uninstall cbftp" "Reinstall cbftp" "Update cbftp" "Commandline help" "Exit")
        REPLY=
        # shellcheck disable=SC2034
        select option in "${options[@]}"; do
            case ${REPLY} in
                1)
                    install_cbftp_tools
                    break
                ;;
                2)
                    uninstall_cbftp_tools
                    break
                ;;
                3)
                    reinstall_cbftp_tools
                    break
                ;;
                4)
                    reinstall_cbftp_tools
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
        OPTIONS=$(getopt -o hiurUL --long help,install,uninstall,reinstall,update -n "$0" -- "$@")
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
                    install_cbftp_tools
                    break
                ;;
                -u|--uninstall)
                    uninstall_cbftp_tools
                    break
                ;;
                -r|--reinstall)
                    reinstall_cbftp_tools
                    break
                ;;
                -U|--update)
                    reinstall_cbftp_tools
                    break
                ;;
                -L)
                    symbolic_links
                    break
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
