# Handle args for subcmd: uninstall
# shellcheck shell=bash

showhelp(){
echo -e "Syntax: $0 uninstall [OPTIONS]...

Unintall dots.

Options:
  -h, --help       Show this help message
"
}
# `man getopt` to see more
parse_getopt "h" "help" "$@"
## getopt Phase 1
# ignore parameter's order, execute options below first
eval set -- "$para"
while true ; do
  case "$1" in
    -h|--help) showhelp;exit;;
    --) break ;;
    *) shift ;;
  esac
done
