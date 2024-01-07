#!/bin/bash
###############################################################################################
#
#   Name         :
#       cbftp-crontab-installer.sh
#
#   Description  :
#       Bash script for setting up a crontab for cbftp-updater.
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
###############################################################################################

# Constants
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly CONFIG_FILE="${SCRIPT_DIR}/cbftp-updater.cfg"

# Load configuration
load_configuration() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Configuration file not found at '$CONFIG_FILE'."
        exit 1
    fi

    source "$CONFIG_FILE" || {
        echo "Error: Failed to load configuration from '$CONFIG_FILE'."
        exit 1
    }
}

# Add or update a cron job
add_or_update_cron_job() {
    local script_path=$1
    local frequency=$2
    local cron_expression=""

    [[ -x "$script_path" ]] || {
        echo "Error: Script at '$script_path' is not executable or missing."
        exit 1
    }

    case "$frequency" in
        "hourly") cron_expression="0 * * * *" ;;
        "daily") cron_expression="0 0 * * *" ;;
        "weekly") cron_expression="0 0 * * 0" ;;
        "biweekly") cron_expression="0 0 */2 * *" ;;
        "monthly") cron_expression="0 0 1 * *" ;;
        "remove") remove_cron_job "$script_path" ; exit 0 ;;
        *) echo "Error: Invalid frequency '$frequency'." ; exit 1 ;;
    esac

    update_cron "$script_path" "$cron_expression"
}

# Update cron tab
update_cron() {
    local script="$1"
    local expression="$2"

    crontab -u "$CB_USER" -l 2>/dev/null | grep -v "$script" | crontab -u "$CB_USER" - || {
        echo "Error: Failed to remove existing cron job for '$script'."
        exit 1
    }

    (crontab -u "$CB_USER" -l 2>/dev/null; echo "$expression cd '$SCRIPT_DIR' && '$script'") | crontab -u "$CB_USER" - || {
        echo "Error: Failed to add new cron job for '$script'."
        exit 1
    }

    echo "Cron job successfully updated for $frequency."
}

# Remove cron job
remove_cron_job() {
    local script="$1"
    crontab -u "$CB_USER" -l 2>/dev/null | grep -v "$script" | crontab -u "$CB_USER" - || {
        echo "Error: Failed to remove cron job for '$script'."
        exit 1
    }
    echo "Cron job successfully removed for '$script'."
}


# Show all cron jobs of the user
show_all_cron_jobs() {
    echo "Current cron jobs for user $CB_USER:"
    crontab -u "$CB_USER" -l || {
        echo "Error: Failed to list cron jobs for '$CB_USER'."
        exit 1
    }
}

# Show current frequency of the script in crontab
show_current_frequency() {
    local script="$1"
    local cron_entry=$(crontab -u "$CB_USER" -l 2>/dev/null | grep "$script")
    if [[ -z "$cron_entry" ]]; then
        echo "No cron job found for '$script'."
    else
        echo "Current cron job for '$script':"
        echo "$cron_entry"
    fi
}

# Ensure the script is run as root
check_root() {
    (( EUID != 0 )) && {
        echo "Error: This script requires root privileges."
        exit 1
    }
}

# Interactive frequency selection
selected_frequency=""

select_frequency() {
    printf "Choose the execution frequency:\n"
    printf "1) Every hour\n"
    printf "2) Daily\n"
    printf "3) Weekly\n"
    printf "4) Bi-weekly\n"
    printf "5) Monthly\n"
    printf "6) Remove crontab\n"
    printf "7) Show all crontab of user\n"
    printf "8) Show actual frequency\n"
    printf "9) Quit\n"
    while true; do
        read -p "Enter the number corresponding to the frequency: " choice
        case "$choice" in
            1) selected_frequency="hourly"; break ;;
            2) selected_frequency="daily"; break ;;
            3) selected_frequency="weekly"; break ;;
            4) selected_frequency="biweekly"; break ;;
            5) selected_frequency="monthly"; break ;;
            6) selected_frequency="remove"; break ;;
            7) show_all_cron_jobs; exit 0 ;;
            8) show_current_frequency "$script_path"; exit 0 ;;
            9) exit 0 ;;
            *) printf "Invalid choice. Please try again.\n" ;;
        esac
    done
}

# Help function
show_help() {
    echo "Usage: $0 [-h] [-s script_name] [-f frequency]"
    echo
    echo "Options:"
    echo "  -h              Show this help message"
    echo "  -s script_name  Specify the script name (default: cbftp-updater.sh)"
    echo "  -f frequency    Set the frequency (hourly, daily, weekly, biweekly, monthly)"
}

# Argument handling
frequency_provided=false

while getopts "hs:f:" opt; do
    case "$opt" in
        h) show_help
            exit 0
        ;;
        s) script_name=$OPTARG
        ;;
        f) frequency=$OPTARG
            frequency_provided=true
        ;;
        *) show_help
            exit 1
        ;;
    esac
done

# Main script execution
main() {
    check_root
    load_configuration

    # Initialize script_name with a default value if not provided
    script_name=${script_name:-"cbftp-updater.sh"}
    script_path="${SCRIPT_DIR}/${script_name}"

    # If frequency is not provided, switch to interactive mode
    if ! $frequency_provided; then
        echo "Switching to interactive mode for frequency selection"
        select_frequency
        frequency=$selected_frequency
    fi
    if [[ $frequency == "remove" ]]; then
        remove_cron_job "$script_path"
        exit 0
    fi
    if [[ -f "$script_path" ]]; then
        add_or_update_cron_job "$script_path" "$frequency"
    else
        echo "Error: The file '$script_name' does not exist in '$SCRIPT_DIR'."
    fi
}

main "$@"
