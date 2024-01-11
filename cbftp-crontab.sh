#!/bin/bash
###############################################################################################
#   Name         : cbftp-tools
#
#   Filename     : cbftp-crontab.sh
#
#   Description  :
#       Bash script for setting up a crontab for cbftp-updater.
#
#   Usage        :
#       sudo cbftp-crontab [-h] [-i] [-u]
#
#   Options      :
#       -h, --help         Show this help screen.
#       -i, --install      Install cbftp crontab  [hourly|daily|weekly|biweekly|monthly] (default: weekly).
#       -u, --uninstall    Remove the cbftp crontab.
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

# Constants
set -Eeuo pipefail
export LANG=en_US

SCRIPT_UPDATER="/usr/local/src/cbftp-tools/cbftp-update.sh"

# Add or update a cron job
add_or_update_cron_job() {
    local frequency=$1
    local cron_expression=""

    [[ -x "${SCRIPT_UPDATER}" ]] || {
        echo "Error: The script at '${SCRIPT_UPDATER}' is not executable or missing."
        exit 1
    }

    case "${frequency}" in
        "hourly") cron_expression="0 * * * *";;
        "daily") cron_expression="0 0 * * *";;
        "weekly") cron_expression="0 0 * * 0";;
        "biweekly") cron_expression="0 0 */2 * *";;
        "monthly") cron_expression="0 0 1 * *";;
        "remove") remove_cron_job "${SCRIPT_UPDATER}"; exit 0;;
        *) echo "Error: Invalid frequency '${frequency}'."; exit 1;;
    esac

    update_cron "${SCRIPT_UPDATER}" "${cron_expression}"
}

# Update the cron tab
update_cron() {
    local script="$1"
    local expression="$2"

    crontab -l 2>/dev/null | grep -v "${script}" | crontab - || {
        echo "Error: Failed to remove an existing cron job for '${script}'."
        exit 1
    }

    (crontab -l 2>/dev/null; echo "${expression} '${script}'") | crontab - || {
        echo "Error: Failed to add a new cron job for '${script}'."
        exit 1
    }

    echo "Cron job successfully updated for ${frequency}."
}

# Remove a cron job
remove_cron_job() {
    local script="$1"
    crontab -l 2>/dev/null | grep -v "${script}" | crontab - || {
        echo "Error: Failed to remove a cron job for '${script}'."
        exit 1
    }
    echo "Cron job successfully removed for '${script}'."
}

# Show all cron jobs of the user
show_all_cron_jobs() {
    echo "Current cron jobs for user ${CB_USER}:"
    crontab -l || {
        echo "Error: Failed to list cron jobs for '${CB_USER}'."
        exit 1
    }
}

# Show the current frequency of the script in crontab
show_current_frequency() {
    local script="$1"
    local cron_entry
    cron_entry=$(crontab -l 2>/dev/null | grep "${script}")
    if [[ -z "$cron_entry" ]]; then
        echo "No cron job found for '${script}'."
    else
        echo "Current cron job for '${script}':"
        echo "$cron_entry"
    fi
}

# Ensure the script is run as root
check_root() {
    if [[ ${EUID} -ne 0 ]]; then
        echo "This script requires root privileges. Use 'sudo' or log in as root."
        exit 1
    fi
}

# Uninstall the crontab
crontab_uninstall() {
    echo "Removing the crontab..."
    add_or_update_cron_job "remove"
    echo "Crontab removed."
}

# Install the crontab
crontab_install() {
    local frequency="${1:-weekly}"

    # Verify the argument is valid (hourly, daily, weekly, biweekly, monthly)
    if [[ "${frequency}" != "hourly" && "${frequency}" != "daily" && "${frequency}" != "weekly" && "${frequency}" != "biweekly" && "${frequency}" != "monthly" ]]; then
        echo "Error: Invalid frequency specified."
        show_help
        exit 1
    fi

    echo "Installing the crontab..."
    add_or_update_cron_job "${frequency}"
    echo "Crontab installed."
}

# Help function
show_help() {
    echo "Usage: $0 [-h] [-i] [-u]"
    echo
    echo "Options:"
    echo "  -h              Show this help message"
    echo "  -i|--install    [hourly|daily|weekly|biweekly|monthly] Install the crontab (default: weekly)"
    echo "  -u|--uninstall  Remove the crontab"
}

function core() {

    # Display a menu when no arguments are provided
    if [ $# -eq 0 ]; then
        PS3="Please select an option: "
        options=("Install crontab" "Uninstall crontab" "Command-line help" "Exit")
        REPLY=
        # shellcheck disable=SC2034
        select option in "${options[@]}"; do
            case ${REPLY} in
                1)
                    read -rp "Enter frequency (hourly|daily|weekly|biweekly|monthly), default: weekly: " frequency
                    crontab_install "${frequency}"
                    break
                ;;
                2)
                    crontab_uninstall
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
                    shift
                    crontab_install "$@"
                    break
                ;;
                -u|--uninstall)
                    crontab_uninstall "$@"
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
