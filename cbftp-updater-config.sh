#!/bin/bash
set -Eeuo pipefail
export LANG=en_US
# Script Header
echo "CBFTP Updater Configuration Script"
echo "----------------------------------"

# Constants
CONFIG_FILE="cbftp-configuration.cfg"
DEFAULT_USER=$(whoami)
DEFAULT_DIR_SRC="$HOME/_downloads/cbftp/"
DEFAULT_DIR_DEST="$HOME/_autotrade/cbftp/"
DEFAULT_SVN_URL="https://cbftp.glftpd.io/svn"
DEFAULT_WEBSITE="https://cbftp.glftpd.io/"
DEFAULT_SERVICE="cbftp.service"
DEFAULT_SCREEN="cbftp"

declare -A default_values=(
    [CB_USER]="$DEFAULT_USER"
    [CB_DIR_SRC]="$DEFAULT_DIR_SRC"
    [CB_DIR_DEST]="$DEFAULT_DIR_DEST"
    [CB_SVN_URL]="$DEFAULT_SVN_URL"
    [CB_WEBSITE]="$DEFAULT_WEBSITE"
    [CB_SERVICE]="$DEFAULT_SERVICE"
    [CB_SCREEN]="$DEFAULT_SCREEN"
)

# Functions
ask_overwrite() {
    read -p "Configuration file $CONFIG_FILE already exists. Do you want to overwrite it? (y/n) " overwrite
    [[ "$overwrite" != "y" ]] && { echo "Operation canceled."; exit 1; }
}

write_config_value() {
    echo "$1=\"$2\"" >> "$CONFIG_FILE"
}

read_or_default() {
    read -p "Please enter the value for $1 ($2): " input
    echo "${input:-$2}"
}

check_and_create_directory() {
    [[ ! -d "$1" ]] && { read -p "Directory $1 does not exist. Do you want to create it? (y/n) " create_dir; [[ "$create_dir" == "y" ]] && mkdir -p "$1" || { echo "Operation canceled."; exit 1; }; }
}

# Main script
[[ -e "$CONFIG_FILE" ]] && ask_overwrite

echo "# Configuration" > "$CONFIG_FILE"

for var in "${!default_values[@]}"; do
    value=$(read_or_default "Please enter the value for $var" "${default_values[$var]}")
    write_config_value "$var" "$value"
    [[ "$var" == "CB_DIR_SRC" || "$var" == "CB_DIR_DEST" ]] && check_and_create_directory "$value"
done

echo "Configuration complete. Values have been saved in $CONFIG_FILE."
