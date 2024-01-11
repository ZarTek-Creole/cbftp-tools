#!/bin/bash

###############################################################################################
#   Name         : cbftp-tools
#
#   Filename     : cbftp_tools.sh
#
#   Description  :
#       This Bash script serves as the central component of cbftp-tools.
#
#   Usage        :
#       cbftp-tools [--help|--install|--uninstall|--reinstall|--update|crontab|init.d|systemd|cbftp]
#
#   Options      :
#       -h, --help                         Display this help screen.
#       -i, --install                      Install cbftp-tools.
#       -u, --uninstall                    Uninstall cbftp-tools.
#       -r, --reinstall                    Reinstall cbftp-tools.
#       -U, --update                       Update cbftp-tools to the latest version.
#
#   Subcommands  :
#       cbftp                       Manage the cbftp binary.
#           Suboptions   :
#               -h, --help                 Display this help screen.
#               -i, --install              Install cbftp.
#               -u, --uninstall            Uninstall cbftp.
#               -r, --reinstall            Reinstall/Update cbftp.
#               -U, --update               Update cbftp to the latest version.
#
#       crontab                     Manage the crontab script for automatic updates.
#           Suboptions   :
#               -h, --help                 Display this help screen."
#               -i, --install              [hourly|daily|weekly|biweekly|monthly] Install the crontab (default: weekly)."
#               -u, --uninstall            Remove the crontab."
#
#       init.d                      Manage the init.d script for cbftp.
#           Suboptions   :
#               -h, --help                 Display help.
#               -i, --install   [username] Install the CBFTP service (default: root).
#               -u, --uninstall [username] Uninstall the CBFTP service (default: root).
#               status          [username] Show status of the CBFTP service.
#               restart         [username] Restart the CBFTP service.
#               start           [username] Start the CBFTP service.
#               stop            [username] Stop the CBFTP service.
#               join            [username] Join the screen.
#
#       systemd                     Manage the systemd script for cbftp.
#           Suboptions   :
#               -h, --help                 Display help.
#               -i, --install   [username] Install the CBFTP service (default: root).
#               -u, --uninstall [username] Uninstall the CBFTP service (default: root).
#               status          [username] Show status of the CBFTP service.
#               restart         [username] Restart the CBFTP service.
#               start           [username] Start the CBFTP service.
#               stop            [username] Stop the CBFTP service.
#               join            [username] Join the screen.
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

show_banner() {
    echo "###################################################################################################"
    echo "#"
    echo "#   Welcome to cbftp-tools"
    echo "#"
    echo "###################################################################################################"
    echo "#"
    echo "#   Donations        : https://github.com/ZarTek-Creole/DONATE"
    echo "#   Author           : ZarTek"
    echo "#   Repository       : https://github.com/ZarTek-Creole/cbftp-tools"
    echo "#   Support          : https://github.com/ZarTek-Creole/cbftp-tools/issues"
    echo "#"
    echo "###################################################################################################"
    echo "#"
    echo "#   Acknowledgements :"
    echo "#"
    echo "#   Special thanks to the cbftp project, PCFiL, harrox, deeps, and all developers in the scene."
    echo "#   Special thanks to all the contributors and users of cbftp-updater for their support"
    echo "#   and contributions to the project."
    echo "#"
    echo "###################################################################################################"
    echo ""
}

show_help() {
    echo "Interactive mode: What would you like to do today?"
    echo ""
    echo "Usage: $0 [--help|--install|--uninstall|--reinstall|--update|crontab|init.d|systemd|cbftp]"
    echo "Options:"
    echo "  -h, --help                         Display this help screen."
    echo "  -i, --install                      Install cbftp-tools."
    echo "  -u, --uninstall                    Uninstall cbftp-tools."
    echo "  -r, --reinstall                    Reinstall cbftp-tools."
    echo "  -U, --update                       Update cbftp-tools to the latest version."
    echo ""
    echo "  cbftp                       Manage the cbftp binary."
    echo "      Options:"
    echo "          -h, --help                 Display this help screen."
    echo "          -i, --install              Install cbftp."
    echo "          -u, --uninstall            Uninstall cbftp."
    echo "          -r, --reinstall            Reinstall/Update cbftp."
    echo "          -U, --update               Update cbftp to the latest version."
    echo ""
    echo "  crontab                     Manage the crontab script for automatic updates."
    echo "      Options:"
    echo "          -h, --help                 Display this help screen."
    echo "          -i, --install              [hourly|daily|weekly|biweekly|monthly] Install the crontab (default: weekly)."
    echo "          -u, --uninstall            Remove the crontab."
    echo ""
    echo "  init.d                      Manage the init.d script for cbftp."
    echo "      Options:"
    echo "          -h, --help                 Display help."
    echo "          -i, --install   [username] Install the CBFTP service (default: root)."
    echo "          -u, --uninstall [username] Uninstall the CBFTP service (default: root)."
    echo "          status          [username] Show status of the CBFTP service."
    echo "          restart         [username] Restart the CBFTP service."
    echo "          start           [username] Start the CBFTP service."
    echo "          stop            [username] Stop the CBFTP service."
    echo "          join            [username] Join the screen."
    echo ""
    echo "  systemd                     Manage the systemd script for cbftp."
    echo "      Options:"
    echo "          -h, --help                 Display help."
    echo "          -i, --install   [username] Install the CBFTP service (default: root)."
    echo "          -u, --uninstall [username] Uninstall the CBFTP service (default: root)."
    echo "          status          [username] Show status of the CBFTP service."
    echo "          restart         [username] Restart the CBFTP service."
    echo "          start           [username] Start the CBFTP service."
    echo "          stop            [username] Stop the CBFTP service."
    echo "          join            [username] Join the screen."
    echo ""
}

cbftp_tools() {
    /usr/local/bin/cbftp-tools_install "$@"
}

cbftp_install_script() { 
    /usr/local/bin/cbftp_install "$@"
}

run_crontab_script() {
    /usr/local/bin/cbftp-crontab "$@"
}

run_initd_script() {
    /usr/local/bin/cbftp-init.d "$@"
}

run_systemd_script() {
    /usr/local/bin/cbftp-systemd "$@"
    exit 0
}

function core(){
    # Check command-line arguments
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi

    # Process command-line options
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -i|--install)
                cbftp_tools "$@" 
                break
                ;;
            -u|--uninstall)
                cbftp_tools "$@"
                break
                ;;
            -r|--reinstall)
                cbftp_tools "$@"
                break
                ;;
            -U|--update)
                cbftp_tools "$@"
                break
                ;;
            crontab)
                shift
                run_crontab_script "$@"
                break
                ;;
            init.d)
                shift
                run_initd_script "$@"
                break
                ;;
            systemd)
                shift
                run_systemd_script "$@"
                break
                ;;
            cbftp)
                shift
                cbftp_install_script "$@"
                break
                ;;
            *)
                echo "Invalid option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

main() {
    show_banner
    core "$@"
}

main "$@"
exit 0
