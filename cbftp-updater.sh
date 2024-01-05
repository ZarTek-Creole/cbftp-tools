#!/bin/bash

###############################################################################################
#
#   Nom         :
#       cbftp-updater.sh
#
#   Description :
#       Script Bash pour la gestion et la mise à jour automatique de cbftp via Subversion (SVN).
#       Simplifiez la tâche de maintenir votre installation cbftp à jour avec ce script efficace.
#
#   Donations   :
#       https://github.com/ZarTek-Creole/DONATE
#
#	Auteur		:
#		ZarTek @ https://github.com/ZarTek-Creole
#
#   Repository  :
#       https://github.com/ZarTek-Creole/cbftp-updater
#
#   Support     :
#       https://github.com/ZarTek-Creole/cbftp-updater/issues
#
#
#   Remerciements :
#       À tous les contributeurs et utilisateurs de cbftp-updater
#
###############################################################################################

set -Eeuo pipefail

# Configuration
CBUSER=mon_utilisateur
CBSERVICE=service.cbftp
CBDIRSRC="/chemin/vers/le/repertoire/source"
CBDIRDEST="/chemin/vers/le/repertoire/destination"
SVN_URL="https://cbftp.glftpd.io/svn"

trap 'echo "Erreur lors de l exécution du script: $BASH_COMMAND" ; exit 1' ERR

check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "Ce script nécessite des privilèges root. Utilisez 'sudo' ou connectez-vous en tant que root."
        exit 1
    fi
}

check_dependencies() {
    local dependencies=(svn make systemctl)
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Erreur: $cmd est requis mais n'est pas installé. Installez-le avec 'sudo apt-get install $cmd'."
            exit 1
        fi
    done
}

verify_directory() {
    if [ ! -d "$1" ]; then
        echo "Le répertoire $1 n'existe pas. Veuillez vérifier le chemin et réessayer."
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
        echo "Initialisation du dépôt SVN dans $CBDIRSRC"
        svn checkout "$SVN_URL" "$CBDIRSRC"
    else
        local current_url=$(get_svn_info "$CBDIRSRC" repos-root-url)
        if [ "$current_url" != "$SVN_URL" ]; then
            echo "Mise à jour de l URL du dépôt SVN. changement de $current_url à $SVN_URL"
            svn relocate "$SVN_URL" "$CBDIRSRC"
        fi
    fi
}

main() {
    echo "Début de la mise à jour de cbftp."
    check_root
    check_dependencies
    initialize_or_update_svn
    verify_directory "$CBDIRSRC"

    local local_rev=$(get_svn_info "$CBDIRSRC" last-changed-revision)
    local remote_rev=$(get_svn_info "$CBDIRSRC" revision)

    if [ "$local_rev" == "$remote_rev" ]; then
        echo "Dernière version de cbftp déjà installée (révision: $local_rev)."
        exit 0
    fi

    echo "Mise à jour de cbftp de la révision $local_rev à $remote_rev."
    update_sources
    build_cbftp
    deploy_cbftp
    restart_service
    echo "Mise à jour de cbftp terminée avec succès."
}

main "$@"
