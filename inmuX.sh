#!/data/data/com.termux/files/usr/bin/bash

# Couleurs ANSI
green="\033[32;1m"
yellow="\033[33;1m"
blue="\033[34;1m"
red="\033[31;1m"
cyan="\033[36;1m"
reset="\033[0m"

# Retour au menu
reas() {
    echo -e "$reset"
    read -p "B/back or E/Exit : " be
    if [ "$be" = "B" ]; then
        menu
    else
        echo "Bye :)"
        exit
    fi
}

# Fonction API
fetch_api() {
    endpoint=$1
    label=$2
    echo -e "${cyan}╭─SOLITAIRE@localhost ~/SNI-SCAN${reset}"
    read -p "╰─>~# " target
    mkdir -p resultats
    outfile="resultats/result_${endpoint}_${target}.txt"
    wget "https://api.hackertarget.com/${endpoint}/?q=$target" -q -O "$outfile"
    echo -e "\n${yellow}[+] Résultat : $label${reset}"
    echo -e "$green"
    cat "$outfile"
    echo -e "\n${green}[✓] Résultat sauvegardé : $outfile${reset}"
    reas
}

# Lire rapport
view_reports() {
    clear
    echo -e "${yellow}== Rapports enregistrés ==${reset}"
    [ ! -d "resultats" ] && echo "Aucun dossier." && sleep 2 && menu
    files=$(ls resultats)
    [ -z "$files" ] && echo "Aucun fichier." && sleep 1 && menu
    echo "$files"
    read -p "Fichier à lire : " selected
    if [ -f "resultats/$selected" ]; then
        cat "resultats/$selected"
    else
        echo "Introuvable."
    fi
    reas
}

# Supprimer un rapport
delete_report() {
    clear
    echo -e "${yellow}== Supprimer un rapport ==${reset}"
    ls resultats 2>/dev/null
    read -p "Fichier à supprimer : " to_delete
    if [ -f "resultats/$to_delete" ]; then
        rm "resultats/$to_delete"
        echo -e "${red}Supprimé : resultats/$to_delete${reset}"
    else
        echo "Introuvable."
    fi
    reas
}

# Supprimer tous
delete_all_reports() {
    clear
    echo -e "${red}Tout supprimer ? (o/n)${reset}"
    read -p "> " confirm
    if [ "$confirm" = "o" ]; then
        rm -rf resultats/*
        echo -e "${green}✔ Tous les rapports supprimés.${reset}"
    else
        echo "Annulé."
    fi
    sleep 1
    menu
}

# Mode d'emploi
mode_emploi() {
    clear
    echo -e "${cyan}====== MODE D’EMPLOI ======${reset}"
    echo
    echo -e "${green}1. Prérequis :${reset}"
    echo "   pkg update && pkg upgrade -y"
    echo "   pkg install bash wget -y"
    echo
    echo -e "${green}2. Lancer :${reset}"
    echo "   chmod +x solitaire_hack_inmux.sh"
    echo "   bash solitaire_hack_inmux.sh"
    echo
    echo -e "${green}3. Menu :${reset}"
    echo "   1-11 : Scans réseau"
    echo "   12   : Voir rapports"
    echo "   13   : Supprimer un rapport"
    echo "   14   : Supprimer tous"
    echo "   98   : Mode d'emploi"
    echo "   99   : À propos"
    echo "   00   : Quitter"
    echo
    reas
}

# Menu principal
menu() {
    clear
    echo -e "${red}╔══════════════════════════════════════╗"
    echo -e "║   SOLITAIRE HACK - SNI SCANNER       ║"
    echo -e "╚══════════════════════════════════════╝${reset}"
    echo
    echo -e "${blue}~{1}  DNS Lookup${reset}"
    echo -e "${green}~{2}  Reverse DNS Lookup${reset}"
    echo -e "${blue}~{3}  Whois Lookup${reset}"
    echo -e "${green}~{4}  GeoIP Lookup${reset}"
    echo -e "${blue}~{5}  Host Finder${reset}"
    echo -e "${green}~{6}  HTTP Header${reset}"
    echo -e "${blue}~{7}  Host DNS${reset}"
    echo -e "${green}~{8}  Port Scanner${reset}"
    echo -e "${blue}~{9}  Subnet Lookup${reset}"
    echo -e "${green}~{10} Zone Transfer${reset}"
    echo -e "${blue}~{11} Extract Links${reset}"
    echo -e "${green}~{12} Voir rapports${reset}"
    echo -e "${blue}~{13} Supprimer un rapport${reset}"
    echo -e "${green}~{14} Supprimer tous les rapports${reset}"
    echo
    echo -e "${cyan}~{98} Mode d’emploi${reset}"
    echo -e "${cyan}~{99} À propos${reset}"
    echo -e "${cyan}~{00} Quitter${reset}"
    echo
    read -p "╰─>~# " select

    case $select in
        1) fetch_api "dnslookup" "DNS Lookup" ;;
        2) fetch_api "reverseiplookup" "Reverse DNS" ;;
        3) fetch_api "whois" "Whois Lookup" ;;
        4) fetch_api "geoip" "GeoIP Lookup" ;;
        5) fetch_api "hostsearch" "Host Finder" ;;
        6) fetch_api "httpheaders" "HTTP Header" ;;
        7) fetch_api "mtr" "Host DNS" ;;
        8) fetch_api "nmap" "Port Scanner" ;;
        9) fetch_api "subnetcalc" "Subnet Lookup" ;;
        10) fetch_api "zonetransfer" "Zone Transfer" ;;
        11) fetch_api "pagelinks" "Extract Links" ;;
        12) view_reports ;;
        13) delete_report ;;
        14) delete_all_reports ;;
        98) mode_emploi ;;
        99)
            echo -e "${cyan}
Auteur    : SOLITAIRE HACK
Version   : 1.0
WhatsApp  : +2250500448208 / +2250501945735
GitHub    : github.com/solitaire-hack${reset}"
            reas ;;
        00) echo "À bientôt !"; exit ;;
        *) echo "Option invalide."; sleep 1; menu ;;
    esac
}

menu