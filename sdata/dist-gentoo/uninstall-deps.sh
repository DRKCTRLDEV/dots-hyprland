# This script is meant to be sourced.
# It's not for directly running.

source ./sdata/dist-gentoo/metapkgs.sh

for i in "${GENTOO_METAPKG_NAMES[@]}"; do
  v sudo emerge --unmerge $i
done

v sudo emerge --depclean
