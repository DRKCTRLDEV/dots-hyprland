# This script is meant to be sourced.
# It's not for directly running.

# shellcheck shell=bash

#####################################################################################

case $ask in
  false) sleep 0 ;;
  *) 
    printf "${STY_BLUE}"
    printf "${STY_BOLD}Do you want to confirm every time before a command executes?${STY_RST}\n"
    printf "${STY_BLUE}"
    printf "  y = Yes, ask me before executing each of them. (DEFAULT)\n"
    printf "  n = No, I know everything this script will do, just execute them automatically.\n"
    printf "  a = Abort.\n"
    read -p "===> [Y/n/a]: " p
    case $p in
      n) ask=false ;;
      a) exit 1 ;;
      *) ask=true ;;
    esac
    printf "${STY_RST}"
    ;;
esac
