# Handle args for subcmd: checkdeps
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 resetfirstrun [OPTIONS]

Reset firstrun state.

Options:
  -h, --help       Show this help message and exit
"
}
# `man getopt` to see more
parse_getopt "c" "help" "$@"
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) shift;break ;;
    *) echo -e "$0: Wrong parameters.";exit 1;;
  esac
done
